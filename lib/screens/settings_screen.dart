import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../ui/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/source_provider.dart';
import '../services/credentials_service.dart';
import '../ui/reader_ui.dart';

/// Leftover credentials files in the cache (they hold the sign-ins): removed at start and before a
/// new export. share_plus copies what it shares into cache/share_plus, so that folder goes too.
Future<void> clearCredentialsCache() async {
  try {
    final tmp = await getTemporaryDirectory();
    for (final name in ['credentials', 'share_plus']) {
      final d = Directory('${tmp.path}/$name');
      if (await d.exists()) {
        await for (final f in d.list()) {
          if (f is File && f.path.split('/').last.startsWith('readers-credentials')) await f.delete();
        }
      }
    }
  } catch (_) {}
}

Future<void> exportCredentials(BuildContext context) async {
  final text = buildCredentials(context.read<SourceProvider>().sources);
  if (text == null) { say(context, t('no paid Substack to export')); return; }
  await clearCredentialsCache();
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/credentials');
  await dir.create(recursive: true);
  final file = File('${dir.path}/readers-credentials-feeds.json');
  await file.writeAsString(text);
  await Share.shareXFiles([XFile(file.path, mimeType: 'application/json', name: 'readers-credentials-feeds.json')],
      subject: t("Reader's Feeds credentials — the file holds your Substack sign-ins: keep it private"));
}

Future<void> importCredentials(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  final path = result?.files.single.path;
  if (path == null || !context.mounted) return;
  try {
    final incoming = readCredentials(await File(path).readAsString());
    if (!context.mounted) return;
    final n = await context.read<SourceProvider>().applySubstackSignIns(incoming);
    if (context.mounted) say(context, t('%1 Substack sign-ins imported', [n]));
  } on CredentialsError catch (e) {
    if (context.mounted) say(context, e.kind == 'foreign' ? t("not a Reader's credentials file") : t('this file holds nothing for %1', ["Reader's Feeds"]));
  } catch (e) {
    if (context.mounted) say(context, t('could not import: %1', [e]));
  }
}

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
            TextRow(t('export credentials'), secondary: t('a file to set up another device — it holds your Substack sign-ins'), secondaryLines: 2, onTap: () => exportCredentials(context)),
            TextRow(t('import credentials'), secondary: t('Substack sign-ins from a credentials file'), secondaryLines: 2, onTap: () => importCredentials(context)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Rule()),
            TextRow("Reader's Feeds", secondary: t('a black-and-white RSS reader, born from Pluralis. GPL-3.0.'), maxLines: 1, secondaryLines: 3),
            TextRow(t('Pierre Gallaz · developed with Claude Code'), dim: true),
          ]),
        ),
      ]),
    );
  }
}
