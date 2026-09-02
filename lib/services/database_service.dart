import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/clipboard_item.dart';

const trashRetentionDays = 30;

class DatabaseService {
  Database? _db;

  Future<Database> get _database async {
    final db = _db;
    if (db != null) return db;
    return _db = await _open();
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    final supportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(supportDir.path, 'clipboard_history.db');
    return databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE clipboard_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT NOT NULL,
              copied_at INTEGER NOT NULL,
              deleted_at INTEGER
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_clipboard_content ON clipboard_items(content)',
          );
          await db.execute(
            'CREATE INDEX idx_clipboard_copied_at ON clipboard_items(copied_at)',
          );
        },
      ),
    );
  }

  /// Records a fresh copy of [content], appending it to the top of history.
  /// If the same text is already the newest active entry, or already exists
  /// elsewhere in history/trash, it is moved to the top instead of creating
  /// a duplicate row.
  Future<void> recordCopy(String content) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'clipboard_items',
        columns: ['id'],
        where: 'content = ?',
        whereArgs: [content],
        orderBy: 'copied_at DESC',
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await txn.update(
          'clipboard_items',
          {'copied_at': now, 'deleted_at': null},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await txn.insert('clipboard_items', {
          'content': content,
          'copied_at': now,
          'deleted_at': null,
        });
      }
    });
  }

  Future<List<ClipboardItem>> getHistory() async {
    final db = await _database;
    final rows = await db.query(
      'clipboard_items',
      where: 'deleted_at IS NULL',
      orderBy: 'copied_at DESC',
    );
    return rows.map(ClipboardItem.fromMap).toList();
  }

  Future<List<ClipboardItem>> getTrash() async {
    final db = await _database;
    final rows = await db.query(
      'clipboard_items',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(ClipboardItem.fromMap).toList();
  }

  Future<void> moveToTrash(int id) async {
    final db = await _database;
    await db.update(
      'clipboard_items',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Moves every active (non-trashed) item to Trash.
  Future<void> moveAllToTrash() async {
    final db = await _database;
    await db.update(
      'clipboard_items',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'deleted_at IS NULL',
    );
  }

  Future<void> restore(int id) async {
    final db = await _database;
    await db.update(
      'clipboard_items',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteForever(int id) async {
    final db = await _database;
    await db.delete('clipboard_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> emptyTrash() async {
    final db = await _database;
    await db.delete('clipboard_items', where: 'deleted_at IS NOT NULL');
  }

  /// Permanently removes trashed items older than [trashRetentionDays].
  Future<void> purgeExpiredTrash() async {
    final db = await _database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: trashRetentionDays))
        .millisecondsSinceEpoch;
    await db.delete(
      'clipboard_items',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }
}
