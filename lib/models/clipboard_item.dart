class ClipboardItem {
  const ClipboardItem({
    required this.id,
    required this.content,
    required this.copiedAt,
    this.deletedAt,
  });

  final int id;
  final String content;
  final DateTime copiedAt;
  final DateTime? deletedAt;

  bool get isTrashed => deletedAt != null;

  factory ClipboardItem.fromMap(Map<String, Object?> map) {
    return ClipboardItem(
      id: map['id'] as int,
      content: map['content'] as String,
      copiedAt: DateTime.fromMillisecondsSinceEpoch(map['copied_at'] as int),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int),
    );
  }
}
