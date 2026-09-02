import 'package:flutter/material.dart';

import '../../models/clipboard_item.dart';
import '../../utils/time_format.dart';
import '../theme.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
    this.subtitleOverride,
    this.maxLines = 2,
    this.dense = false,
  });

  final ClipboardItem item;
  final VoidCallback onTap;
  final List<Widget>? trailing;
  final String? subtitleOverride;
  final int maxLines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = item.content.replaceAll('\n', '  ').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tileRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: dense ? 8 : 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.isEmpty ? '(empty)' : preview,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleOverride ?? formatRelativeTime(item.copiedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                ...trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
