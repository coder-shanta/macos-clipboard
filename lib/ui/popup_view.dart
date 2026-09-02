import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:provider/provider.dart';

import '../services/clipboard_store.dart';
import '../services/window_controller.dart';
import 'theme.dart';
import 'widgets/glass_container.dart';
import 'widgets/history_tile.dart';

class PopupView extends StatelessWidget {
  const PopupView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<ClipboardStore>();
    final items = store.menuBarItems;

    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        elevated: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 9),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, accentColor.withValues(alpha: 0.72)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Iconify(HeroiconsSolid.clipboard, size: 13, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Clipboard',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(ready: store.ready)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: theme.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return HistoryTile(
                          item: item,
                          dense: true,
                          onTap: () async {
                            await store.recopy(item);
                            if (context.mounted) {
                              await context.read<WindowController>().hideWindow();
                            }
                          },
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<WindowController>().showFullHistory(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Iconify(
                        HeroiconsSolid.clock,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 9),
                      Text('Full History', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      Iconify(
                        HeroiconsSolid.chevron_right,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Iconify(
              HeroiconsSolid.inbox,
              size: 26,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              ready ? 'No copied text yet' : 'Loading…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
