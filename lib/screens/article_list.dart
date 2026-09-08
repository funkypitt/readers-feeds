// The list of articles used by the feed, a source and the saved page: title in the
// foreground, source and age in a dim line under it. Scrolls, or turns pages when the
// setting says so (e-ink): a fixed number of rows per page, tap the lower/upper half.
import 'package:flutter/material.dart';
import '../ui/l10n.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/reader_ui.dart';
import 'article_reader_screen.dart';

class ArticleList extends StatefulWidget {
  final List<Article> articles;
  final Future<void> Function()? onRefresh;
  final String empty;
  final bool showSource;
  const ArticleList({super.key, required this.articles, this.onRefresh, this.empty = 'nothing here', this.showSource = true});

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  int _page = 0;

  void openArticle(BuildContext context, Article a) {
    Navigator.push(context, readerRoute(ArticleReaderScreen(article: a)));
  }

  void articleMenu(BuildContext context, Article a) {
    final bookmarks = context.read<BookmarkProvider>();
    final saved = bookmarks.isBookmarked(a.id);
    showTextMenu(context, title: a.title, items: [
      MenuItemText(t('read'), () => openArticle(context, a)),
      MenuItemText(saved ? t('forget') : t('save for later'), () => bookmarks.toggle(a)),
      MenuItemText(t('open in the browser'), () => launchUrl(Uri.parse(a.link), mode: LaunchMode.externalApplication)),
      MenuItemText(t('share'), () => Share.share('${a.title}\n${a.link}')),
    ]);
  }

  Widget row(BuildContext context, Article a, bool saved) {
    final line = [
      if (widget.showSource) a.sourceName,
      timeAgo(a.publishedAt),
      if (saved) t('saved'),
    ].where((s) => s.isNotEmpty).join(' · ');
    return TextRow(a.title, secondary: line.isEmpty ? null : line, onTap: () => openArticle(context, a), onLongPress: () => articleMenu(context, a));
  }

  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    final bookmarks = context.watch<BookmarkProvider>();
    final paged = context.watch<SettingsProvider>().pagedList;
    if (widget.articles.isEmpty) {
      return ListView(children: [Padding(padding: const EdgeInsets.all(kPadH), child: Small(t(widget.empty)))]);
    }
    if (!paged) {
      final list = ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        itemCount: widget.articles.length,
        itemBuilder: (ctx, i) => row(ctx, widget.articles[i], bookmarks.isBookmarked(widget.articles[i].id)),
      );
      return widget.onRefresh == null ? list : RefreshIndicator(color: st.fg, backgroundColor: st.bg, onRefresh: widget.onRefresh!, child: list);
    }
    // Paged: rows of a fixed height (two title lines + one small line) so a page is a page.
    return LayoutBuilder(builder: (ctx, c) {
      final rowH = (st.title * 1.25 * 2 + st.small * 1.25 + kPadV * 1.4);
      final footer = st.small * 1.25 + 24;
      final perPage = ((c.maxHeight - footer) / rowH).floor().clamp(1, 50);
      final pages = (widget.articles.length / perPage).ceil();
      final p = _page.clamp(0, pages - 1);
      final slice = widget.articles.skip(p * perPage).take(perPage).toList();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          // the lower half turns forward, the upper half back — but rows keep their own taps
        },
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200 && p < pages - 1) setState(() => _page = p + 1);
          if (v > 200 && p > 0) setState(() => _page = p - 1);
        },
        child: Column(children: [
          Expanded(
            child: Column(children: [
              for (final a in slice)
                SizedBox(height: rowH, child: row(ctx, a, bookmarks.isBookmarked(a.id))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kPadH, 8, kPadH, 12),
            child: Row(children: [
              GestureDetector(behavior: HitTestBehavior.opaque, onTap: p > 0 ? () => setState(() => _page = p - 1) : null, child: T('‹', size: st.title, color: p > 0 ? st.fg : st.rule)),
              Expanded(child: T('${p + 1} / $pages', size: st.small, color: st.dim, align: TextAlign.center)),
              GestureDetector(behavior: HitTestBehavior.opaque, onTap: p < pages - 1 ? () => setState(() => _page = p + 1) : null, child: T('›', size: st.title, color: p < pages - 1 ? st.fg : st.rule)),
            ]),
          ),
        ]),
      );
    });
  }
}
