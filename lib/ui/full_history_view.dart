import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../services/clipboard_store.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../services/window_controller.dart';
import '../utils/time_format.dart';
import 'about_view.dart';
import 'theme.dart';
import 'widgets/glass_container.dart';
import 'widgets/history_tile.dart';
import 'widgets/section_card.dart';

extension on HistoryPage {
  String get title => switch (this) {
        HistoryPage.history => 'Clipboard History',
        HistoryPage.trash => 'Trash',
        HistoryPage.settings => 'Settings',
        HistoryPage.about => 'About',
      };
}

/// The larger secondary window. Only [HistoryPage.history] is a first-class,
/// always-visible destination — Trash/Settings/About are reached through
/// the overflow ("···") menu in the title bar (or the tray's double-click
/// menu), matching how macOS panels tuck secondary views behind a menu
/// instead of a tab strip.
class FullHistoryView extends StatefulWidget {
  const FullHistoryView({
    super.key,
    this.initialPage = HistoryPage.history,
  });

  final HistoryPage initialPage;

  @override
  State<FullHistoryView> createState() => _FullHistoryViewState();
}

class _FullHistoryViewState extends State<FullHistoryView> {
  late var _page = widget.initialPage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        elevated: false,
        child: Column(
          children: [
            _TitleBar(
              page: _page,
              onBack: () => setState(() => _page = HistoryPage.history),
              onNavigate: (page) => setState(() => _page = page),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: switch (_page) {
                HistoryPage.history => const _HistoryPage(),
                HistoryPage.trash => const _TrashPage(),
                HistoryPage.settings => const _SettingsPage(),
                HistoryPage.about => const AboutTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.page,
    required this.onBack,
    required this.onNavigate,
  });

  final HistoryPage page;
  final VoidCallback onBack;
  final ValueChanged<HistoryPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragToMoveArea(
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            if (page != HistoryPage.history)
              _IconButton(icon: HeroiconsSolid.chevron_left, onTap: onBack)
            else
              const SizedBox(width: 4),
            const SizedBox(width: 4),
            Text(
              page.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            PopupMenuButton<HistoryPage>(
              tooltip: 'More',
              offset: const Offset(0, 32),
              color: theme.colorScheme.surface.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(chipRadius + 4),
                side: BorderSide(color: theme.dividerColor),
              ),
              onSelected: onNavigate,
              itemBuilder: (context) => [
                _menuItem(theme, HistoryPage.trash, HeroiconsSolid.trash, 'Trash'),
                _menuItem(theme, HistoryPage.settings, HeroiconsSolid.cog_6_tooth, 'Settings'),
                _menuItem(theme, HistoryPage.about, HeroiconsSolid.information_circle, 'About'),
              ],
              icon: Iconify(
                HeroiconsSolid.ellipsis_horizontal,
                size: 17,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            _IconButton(
              icon: HeroiconsSolid.x_mark,
              onTap: () => context.read<WindowController>().hideWindow(),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<HistoryPage> _menuItem(
    ThemeData theme,
    HistoryPage value,
    String icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        children: [
          Iconify(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Iconify(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<ClipboardStore>();
    final items = store.history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: items.isEmpty
                    ? null
                    : () => _confirmClearClipboard(context, store),
                icon: Iconify(HeroiconsSolid.trash, size: 15, color: theme.colorScheme.error),
                label: const Text('Clear Clipboard'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _EmptyMessage(
                  icon: HeroiconsSolid.inbox,
                  text: 'No copied text yet',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return HistoryTile(
                      item: item,
                      onTap: () async {
                        await store.recopy(item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(milliseconds: 1200),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      },
                      trailing: [
                        IconButton(
                          tooltip: 'Move to Trash',
                          icon: Iconify(
                            HeroiconsSolid.trash,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => store.moveToTrash(item),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClearClipboard(
    BuildContext context,
    ClipboardStore store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Clipboard?'),
        content: const Text(
          'All history items will be moved to Trash, where they can still '
          'be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Clipboard'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.clearHistory();
    }
  }
}

class _TrashPage extends StatelessWidget {
  const _TrashPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<ClipboardStore>();
    final items = store.trash;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Items are permanently deleted $trashRetentionDays days after being trashed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: items.isEmpty
                    ? null
                    : () => _confirmEmptyTrash(context, store),
                icon: Iconify(
                  HeroiconsSolid.archive_box_x_mark,
                  size: 15,
                  color: theme.colorScheme.error,
                ),
                label: const Text('Empty Trash'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _EmptyMessage(
                  icon: HeroiconsSolid.trash,
                  text: 'Trash is empty',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final remaining = daysUntilPurge(
                      item.deletedAt!,
                      trashRetentionDays,
                    );
                    return HistoryTile(
                      item: item,
                      onTap: () {},
                      subtitleOverride:
                          'Deleted ${formatRelativeTime(item.deletedAt!)} · '
                          '$remaining ${remaining == 1 ? 'day' : 'days'} left',
                      trailing: [
                        IconButton(
                          tooltip: 'Restore',
                          icon: Iconify(
                            HeroiconsSolid.arrow_uturn_left,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => store.restoreFromTrash(item),
                        ),
                        IconButton(
                          tooltip: 'Delete Forever',
                          icon: Iconify(
                            HeroiconsSolid.archive_box_x_mark,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => store.deleteForever(item),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context, ClipboardStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All trashed items will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.emptyTrash();
    }
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<ClipboardStore>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Menu Bar',
          children: [
            SectionRow(
              label: 'Items shown in menu bar',
              showDivider: false,
              trailing: _Stepper(
                value: store.menuBarItemCount,
                min: minMenuBarItemCount,
                max: maxMenuBarItemCount,
                onChanged: store.setMenuBarItemCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'General',
          children: [
            SectionRow(
              label: 'Launch at Login',
              leading: Iconify(
                HeroiconsSolid.arrow_left_on_rectangle,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              showDivider: false,
              trailing: Switch(
                value: store.launchAtLogin,
                onChanged: store.setLaunchAtLogin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Copy history is stored on this Mac for as long as you keep the app. '
          'Deleted items stay in Trash for $trashRetentionDays days before being '
          'removed automatically.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Iconify(
            HeroiconsSolid.minus_circle,
            size: 18,
            color: value > min ? theme.colorScheme.onSurfaceVariant : disabledColor,
          ),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 20,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: Iconify(
            HeroiconsSolid.plus_circle,
            size: 18,
            color: value < max ? theme.colorScheme.onSurfaceVariant : disabledColor,
          ),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(icon, size: 34, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
