// Home: the latest articles of every enabled source. The ⋯ menu leads everywhere else.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/source_provider.dart';
import '../ui/reader_ui.dart';
import 'article_list.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(onlyIfStale: true);
  }

  Future<void> _refresh({bool onlyIfStale = false}) async {
    if (!mounted) return;
    if (onlyIfStale && _lastRefresh != null && DateTime.now().difference(_lastRefresh!).inMinutes < 5) return;
    final sources = context.read<SourceProvider>().activeSources;
    if (sources.isEmpty) return;
    _lastRefresh = DateTime.now();
    await context.read<FeedProvider>().refresh(sources);
  }

  void _initialRefresh() {
    final sp = context.read<SourceProvider>();
    if (sp.activeSources.isNotEmpty) { _refresh(); return; }
    late final void Function() listener;
    listener = () {
      if (!mounted) { sp.removeListener(listener); return; }
      if (sp.activeSources.isNotEmpty) { sp.removeListener(listener); _refresh(); }
    };
    sp.addListener(listener);
  }

  void _menu() {
    final feed = context.read<FeedProvider>();
    final settings = context.read<SettingsProvider>();
    showTextMenu(context, items: [
      MenuItemText('sources', () => Navigator.push(context, readerRoute(const SourcesScreen()))),
      MenuItemText('saved for later', () => Navigator.push(context, readerRoute(const SavedScreen()))),
      MenuItemText('refresh', () => _refresh()),
      MenuItemText(feed.viewMode == FeedViewMode.latest ? 'order: latest first' : 'order: one per source', () => feed.toggleViewMode()),
    ], footer: [
      MenuItemText(settings.dark ? 'black on white' : 'white on black', () => settings.toggleDark()),
      MenuItemText('settings', () => Navigator.push(context, readerRoute(const SettingsScreen()))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    context.read<SettingsProvider>().applyAuto(MediaQuery.sizeOf(context).shortestSide);
    final st = ReaderStyle.of(context);
    final String title;
    if (feed.isLoading && feed.articles.isEmpty) {
      title = 'fetching…';
    } else if (feed.articles.isEmpty) {
      title = 'feeds';
    } else {
      title = '${feed.articles.length} articles · ${feed.sourceCount} sources${feed.isLoading ? ' · …' : ''}';
    }
    final String empty = feed.error != null && feed.articles.isEmpty
        ? 'nothing could be fetched. Pull down to try again, or check the sources.'
        : (context.watch<SourceProvider>().activeSources.isEmpty ? 'no source enabled. ⋯ › sources.' : 'nothing yet. Pull down to refresh.');
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(title, trailing: '⋯', onTrailing: _menu, onTitle: () => _refresh()),
        Expanded(child: ArticleList(articles: feed.articles, onRefresh: _refresh, empty: empty)),
        Container(height: MediaQuery.of(context).padding.bottom, color: st.bg),
      ]),
    );
  }
}
