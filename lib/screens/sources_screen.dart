// The sources: a box to enable, the name to open, a long press for the rest.
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/source.dart';
import '../providers/feed_provider.dart';
import '../providers/source_provider.dart';
import '../services/import_export_service.dart';
import '../ui/reader_ui.dart';
import 'source_feed_screen.dart';
import 'substack_login_screen.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  void _menu(BuildContext context) {
    showTextMenu(context, items: [
      MenuItemText('add a feed', () => _addFeed(context)),
      MenuItemText('add a paid Substack', () => _addSubstack(context)),
      MenuItemText('import OPML', () => _importOpml(context)),
      MenuItemText('export OPML', () => _exportOpml(context)),
      MenuItemText('import Substacks (CSV)', () => _importCsv(context)),
      MenuItemText('export Substacks (CSV)', () => _exportCsv(context)),
    ]);
  }

  Future<void> _addFeed(BuildContext context) async {
    final url = await textPrompt(context, 'address of the feed (or of the site)', hint: 'https://…', keyboard: TextInputType.url);
    if (url == null || url.trim().isEmpty || !context.mounted) return;
    var rss = url.trim();
    if (rss.contains('substack.com') && !rss.endsWith('/feed')) rss = rss.endsWith('/') ? '${rss}feed' : '$rss/feed';
    final host = Uri.tryParse(rss)?.host.replaceAll('www.', '') ?? rss;
    final name = await textPrompt(context, 'name', initial: host);
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    context.read<SourceProvider>().addSource(Source(id: id, name: name.trim(), url: rss, rss: rss, category: 'custom', lang: 'EN', isDefault: false));
  }

  Future<void> _addSubstack(BuildContext context) async {
    final url = await textPrompt(context, 'address of the publication', hint: 'https://example.substack.com', keyboard: TextInputType.url);
    if (url == null || url.trim().isEmpty || !context.mounted) return;
    final cookie = await Navigator.push<String>(context, readerRoute(const SubstackLoginScreen()));
    if (cookie == null || !context.mounted) return;
    final u = url.trim();
    final name = Uri.tryParse(u)?.host.replaceAll('.substack.com', '').replaceAll('www.', '') ?? u;
    final id = 'substack_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
    context.read<SourceProvider>().addSource(Source(id: id, name: name, url: u, rss: u.endsWith('/feed') ? u : '$u/feed', category: 'substack', lang: 'EN', tag: 'paid', isDefault: false, cookie: cookie));
  }

  Future<void> _exportOpml(BuildContext context) async {
    final sources = context.read<SourceProvider>().sources;
    final service = ImportExportService();
    final tmp = await getTemporaryDirectory();
    final file = await service.writeToTempFile(service.exportOpml(sources), 'readers_feeds.opml', tmp.path);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _importOpml(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    try {
      final sources = ImportExportService().importOpml(await File(path).readAsString());
      if (!context.mounted) return;
      if (sources.isEmpty) { say(context, 'no source in this file'); return; }
      await context.read<SourceProvider>().addSources(sources);
      if (context.mounted) say(context, '${sources.length} sources added');
    } catch (e) {
      if (context.mounted) say(context, 'could not import: $e');
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final sources = context.read<SourceProvider>().sources;
    if (!sources.any((s) => s.cookie != null && s.cookie!.isNotEmpty)) { say(context, 'no paid Substack to export'); return; }
    final service = ImportExportService();
    final tmp = await getTemporaryDirectory();
    final file = await service.writeToTempFile(service.exportSubstackCsv(sources), 'readers_feeds_substacks.csv', tmp.path);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _importCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    try {
      final sources = ImportExportService().importSubstackCsv(await File(path).readAsString());
      if (!context.mounted) return;
      if (sources.isEmpty) { say(context, 'no Substack in this file'); return; }
      await context.read<SourceProvider>().addSources(sources);
      if (context.mounted) say(context, '${sources.length} Substacks added');
    } catch (e) {
      if (context.mounted) say(context, 'could not import: $e');
    }
  }

  void _sourceMenu(BuildContext context, Source s) {
    final provider = context.read<SourceProvider>();
    final hasCookie = s.cookie != null && s.cookie!.isNotEmpty;
    showTextMenu(context, title: s.name, items: [
      MenuItemText(s.active ? 'disable' : 'enable', () => provider.toggleSource(s.id)),
      MenuItemText('articles', () => Navigator.push(context, readerRoute(SourceFeedScreen(source: s)))),
      if (hasCookie) MenuItemText('sign in again', () async {
        final cookie = await Navigator.push<String>(context, readerRoute(const SubstackLoginScreen()));
        if (cookie != null) provider.updateSourceCookie(s.id, cookie);
      }),
      if (hasCookie) MenuItemText('forget the sign-in', () => provider.updateSourceCookie(s.id, null)),
      MenuItemText('remove', () => provider.removeSource(s.id)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    final provider = context.watch<SourceProvider>();
    final answered = context.watch<FeedProvider>().activeSourceIds;
    final sources = provider.sources;
    return ReaderPage(
      child: Column(children: [
        ScreenTitle('sources', onBack: () => Navigator.pop(context), trailing: '⋯', onTrailing: () => _menu(context)),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(top: 6, bottom: 32), children: [
            if (sources.isEmpty) const Padding(padding: EdgeInsets.all(kPadH), child: Small('no source yet. ⋯ › add a feed, or import an OPML file.')),
            for (final s in sources)
              Row(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => provider.toggleSource(s.id),
                  child: Padding(padding: const EdgeInsets.only(left: kPadH, right: 14, top: 12, bottom: 12), child: T(s.active ? '■' : '□', size: st.title, color: s.active ? st.fg : st.dim)),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(context, readerRoute(SourceFeedScreen(source: s))),
                    onLongPress: () => _sourceMenu(context, s),
                    child: Padding(
                      padding: const EdgeInsets.only(right: kPadH, top: 12, bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        T(s.name, size: st.title, color: s.active ? st.fg : st.dim, maxLines: 1),
                        Small([
                          if (s.cookie != null && s.cookie!.isNotEmpty) 'signed in',
                          if (s.active && answered.isNotEmpty && !answered.contains(s.id)) 'no answer',
                          Uri.tryParse(s.rss)?.host.replaceAll('www.', '') ?? s.rss,
                        ].join(' · '), maxLines: 1),
                      ]),
                    ),
                  ),
                ),
              ]),
          ]),
        ),
        const Rule(),
        TextRow('+ add a feed', onTap: () => _addFeed(context)),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}
