import 'package:flutter/material.dart';
import '../ui/l10n.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../ui/reader_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(t('settings'), onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(top: 6, bottom: 32), children: [
            TextRow(s.dark ? t('white on black') : t('black on white'), secondary: t('colours'), onTap: s.toggleDark),
            TextRow('${s.fontSize.toInt()}${s.fontSizeIsAuto ? t(' · auto') : ''}', secondary: t('text size — tap for larger, long-press for smaller'), onTap: s.increaseFontSize, onLongPress: s.decreaseFontSize),
            TextRow(t('back to the automatic size'), secondary: t('from the screen size'), onTap: () => s.resetFontSize(context)),
            TextRow(s.serif ? t('serif') : t('sans-serif'), secondary: t('reading face'), onTap: s.toggleSerif),
            TextRow(s.pagedList ? t('pages') : t('scrolling'), secondary: t('lists — pages suit e-ink screens'), onTap: s.togglePagedList),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Rule()),
            TextRow("Reader's Feeds", secondary: t('a black-and-white RSS reader, born from Pluralis. GPL-3.0.'), maxLines: 1, secondaryLines: 3),
            TextRow(t('Pierre Gallaz · developed with Claude Code'), dim: true),
          ]),
        ),
      ]),
    );
  }
}
