import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import 'widgets/section_card.dart';

const _repoUrl = 'https://github.com/coder-shanta/macos-clipboard';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: cardShadow(theme.brightness),
                ),
                child: const Center(
                  child: Iconify(
                    HeroiconsSolid.clipboard_document_list,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clipboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'A fast, native clipboard manager for macOS.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  final label = info == null
                      ? ' '
                      : 'Version ${info.version} (${info.buildNumber})';
                  return Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Developer',
          children: [
            SectionRow(
              label: 'Shanta Miah',
              subtitle: 'coder.shanta@gmail.com',
              leading: const _RowIcon(HeroiconsSolid.user_circle),
              trailing: const _RowIcon(HeroiconsSolid.envelope),
              onTap: () => _launch(
                context,
                Uri(scheme: 'mailto', path: 'coder.shanta@gmail.com'),
              ),
            ),
            SectionRow(
              label: 'shanta.dev',
              subtitle: 'Website',
              leading: const _RowIcon(HeroiconsSolid.globe_alt),
              trailing: const _RowIcon(HeroiconsSolid.arrow_top_right_on_square),
              showDivider: false,
              onTap: () => _launch(context, Uri.https('shanta.dev')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Feedback',
          children: [
            SectionRow(
              label: 'Report a Bug',
              subtitle: 'Something not working right?',
              leading: const _RowIcon(HeroiconsSolid.exclamation_triangle),
              trailing: const _RowIcon(HeroiconsSolid.arrow_top_right_on_square),
              onTap: () => _launch(
                context,
                Uri.parse('$_repoUrl/issues/new?template=bug_report.yml'),
              ),
            ),
            SectionRow(
              label: 'Request a Feature',
              subtitle: 'Have an idea to make it better?',
              leading: const _RowIcon(HeroiconsSolid.light_bulb),
              trailing: const _RowIcon(HeroiconsSolid.arrow_top_right_on_square),
              showDivider: false,
              onTap: () => _launch(
                context,
                Uri.parse('$_repoUrl/issues/new?template=feature_request.yml'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Icons',
          children: [
            SectionRow(
              label: 'Heroicons',
              subtitle: 'Solid icon set, by Tailwind Labs',
              leading: const _RowIcon(HeroiconsSolid.cube),
              trailing: const _LicenseRow(license: 'MIT'),
              onTap: () => _launch(context, Uri.https('heroicons.com')),
            ),
            SectionRow(
              label: 'Iconify',
              subtitle: 'Framework used to embed them',
              leading: const _RowIcon(HeroiconsSolid.cube),
              trailing: const _LicenseRow(license: 'MIT'),
              showDivider: false,
              onTap: () => _launch(context, Uri.https('iconify.design')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Open Source Packages',
          children: [
            for (final pkg in _packages)
              SectionRow(
                label: pkg.name,
                subtitle: pkg.description,
                trailing: _LicenseRow(license: pkg.license),
                showDivider: pkg != _packages.last,
                onTap: () =>
                    _launch(context, Uri.https('pub.dev', '/packages/${pkg.name}')),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Built with Flutter. Thanks to the maintainers of every package '
            'and icon set above for making their work freely available.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Iconify(
      icon,
      size: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// A small license pill plus the external-link glyph, used as the
/// trailing content of a tappable credit row.
class _LicenseRow extends StatelessWidget {
  const _LicenseRow({required this.license});

  final String license;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(chipRadius),
          ),
          child: Text(
            license,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Iconify(
          HeroiconsSolid.arrow_top_right_on_square,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _PackageCredit {
  const _PackageCredit(this.name, this.description, this.license);

  final String name;
  final String description;
  final String license;
}

const _packages = [
  _PackageCredit('tray_manager', 'Menu bar tray icon', 'MIT'),
  _PackageCredit('window_manager', 'Popup and window control', 'MIT'),
  _PackageCredit('macos_window_utils', 'Native window vibrancy/blur', 'MIT'),
  _PackageCredit('clipboard_watcher', 'Clipboard change detection', 'MIT'),
  _PackageCredit('sqflite_common_ffi', 'Local history database', 'BSD-2-Clause'),
  _PackageCredit('screen_retriever', 'Display geometry', 'MIT'),
  _PackageCredit('provider', 'App state management', 'MIT'),
  _PackageCredit('iconify_flutter', 'Icon rendering', 'MIT'),
  _PackageCredit('package_info_plus', 'App version info', 'BSD-3-Clause'),
  _PackageCredit('url_launcher', 'Opening external links', 'BSD-3-Clause'),
];
