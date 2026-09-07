import 'package:flutter/material.dart';
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
        ScreenTitle('settings', onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(top: 6, bottom: 32), children: [
            TextRow(s.dark ? 'white on black' : 'black on white', secondary: 'colours', onTap: s.toggleDark),
            TextRow('${s.fontSize.toInt()}${s.fontSizeIsAuto ? ' · auto' : ''}', secondary: 'text size — tap for larger, long-press for smaller', onTap: s.increaseFontSize, onLongPress: s.decreaseFontSize),
            TextRow('back to the automatic size', secondary: 'from the screen size', onTap: () => s.resetFontSize(context)),
            TextRow(s.serif ? 'serif' : 'sans-serif', secondary: 'reading face', onTap: s.toggleSerif),
            TextRow(s.pagedList ? 'pages' : 'scrolling', secondary: 'lists — pages suit e-ink screens', onTap: s.togglePagedList),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Rule()),
            const TextRow("Reader's Feeds", secondary: 'a black-and-white RSS reader, born from Pluralis. GPL-3.0.', maxLines: 1, secondaryLines: 3),
          ]),
        ),
      ]),
    );
  }
}
