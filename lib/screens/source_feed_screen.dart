import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/source.dart';
import '../services/rss_service.dart';
import '../ui/reader_ui.dart';
import 'article_list.dart';

class SourceFeedScreen extends StatefulWidget {
  final Source source;
  const SourceFeedScreen({super.key, required this.source});
  @override
  State<SourceFeedScreen> createState() => _SourceFeedScreenState();
}

class _SourceFeedScreenState extends State<SourceFeedScreen> {
  final _rss = RssService();
  List<Article> _articles = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final list = await _rss.fetchFeed(widget.source);
    list.sort((a, b) {
      if (a.publishedAt == null) return 1;
      if (b.publishedAt == null) return -1;
      return b.publishedAt!.compareTo(a.publishedAt!);
    });
    if (mounted) setState(() { _articles = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(_loading ? '${widget.source.name} · …' : widget.source.name, onBack: () => Navigator.pop(context)),
        Expanded(child: ArticleList(articles: _articles, onRefresh: _fetch, showSource: false, empty: _loading ? '…' : 'nothing came back from this feed.')),
      ]),
    );
  }
}
