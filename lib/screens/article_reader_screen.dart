// The article as pages: tap the right half for the next page, the left half for the
// previous one. Pages are cut at whole lines, never through a line. Title on the first page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../services/article_extractor_service.dart';
import '../services/text_paginator.dart';
import '../ui/reader_ui.dart';

class ArticleReaderScreen extends StatefulWidget {
  final Article article;
  const ArticleReaderScreen({super.key, required this.article});
  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  final _extractor = ArticleExtractorService();
  final _paginator = TextPaginator();
  ExtractedArticle? _extracted;
  List<String> _pages = [];
  int _page = 0;
  bool _loading = true;
  String? _error;
  // what the current pagination was computed for
  double _forBase = 0; bool _forSerif = false; double _forW = 0, _forH = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final a = widget.article;
    if (a.fullContent != null && a.fullContent!.length > 200) {
      _extracted = ExtractedArticle(title: a.title, content: a.fullContent!, siteName: a.sourceName);
      if (mounted) setState(() => _loading = false);
      return;
    }
    final ex = await _extractor.extract(a.link);
    if (!mounted) return;
    setState(() { _loading = false; _extracted = ex; if (ex == null) _error = 'the text could not be extracted'; });
  }

  void _paginate(ReaderStyle st, double w, double h) {
    if (_extracted == null) return;
    final body = st.text(st.base, height: 1.6);
    final titleTp = TextPainter(text: TextSpan(text: _extracted!.title, style: st.text(st.title, height: 1.25)), textDirection: TextDirection.ltr)..layout(maxWidth: w);
    final headerH = titleTp.height + 14 + 1 + 14; // title, gap, rule, gap
    titleTp.dispose();
    final pages = _paginator.paginate(text: _extracted!.content, width: w, firstPageHeight: h - headerH, pageHeight: h, style: body);
    final progress = _pages.isEmpty ? 0.0 : _page / _pages.length;
    _pages = pages;
    _page = pages.length > 1 ? (progress * pages.length).round().clamp(0, pages.length - 1) : 0;
    _forBase = st.base; _forSerif = st.serif; _forW = w; _forH = h;
  }

  void _menu() {
    final settings = context.read<SettingsProvider>();
    final bookmarks = context.read<BookmarkProvider>();
    final a = widget.article;
    final saved = bookmarks.isBookmarked(a.id);
    showTextMenu(context, title: a.title, items: [
      MenuItemText(saved ? 'forget' : 'save for later', () => bookmarks.toggle(a)),
      MenuItemText('open in the browser', () => launchUrl(Uri.parse(a.link), mode: LaunchMode.externalApplication)),
      MenuItemText('share', () => Share.share('${a.title}\n${a.link}')),
      MenuItemText('larger text', () => settings.increaseFontSize()),
      MenuItemText('smaller text', () => settings.decreaseFontSize()),
      MenuItemText(settings.serif ? 'sans-serif' : 'serif', () => settings.toggleSerif()),
    ], footer: [
      MenuItemText(settings.dark ? 'black on white' : 'white on black', () => settings.toggleDark()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    final a = widget.article;
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(a.sourceName, onBack: () => Navigator.pop(context), trailing: '⋯', onTrailing: _menu),
        Expanded(
          child: _loading
              ? const Padding(padding: EdgeInsets.all(kPadH), child: Small('fetching the text…'))
              : _error != null
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.all(kPadH), child: T(_error!, color: st.dim)),
                      TextRow('open in the browser', onTap: () => launchUrl(Uri.parse(a.link), mode: LaunchMode.externalApplication)),
                    ])
                  : _body(st),
        ),
      ]),
    );
  }

  Widget _body(ReaderStyle st) {
    return LayoutBuilder(builder: (ctx, c) {
      final footerH = st.small * 1.25 + 28;
      final w = c.maxWidth - 2 * kPadH;
      final h = c.maxHeight - footerH - 16 - MediaQuery.of(ctx).padding.bottom;
      if (_forBase != st.base || _forSerif != st.serif || _forW != w || _forH != h) _paginate(st, w, h);
      final last = _pages.length - 1;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          HapticFeedback.selectionClick();
          final x = d.localPosition.dx;
          if (x > c.maxWidth / 2) { if (_page < last) setState(() => _page++); }
          else { if (_page > 0) setState(() => _page--); }
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -100 && _page < last) setState(() => _page++);
          if (v > 100 && _page > 0) setState(() => _page--);
        },
        child: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kPadH, 16, kPadH, 0),
              child: ClipRect(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_page == 0 && _extracted != null) ...[
                    Text(_extracted!.title, style: st.text(st.title, height: 1.25)),
                    const SizedBox(height: 14),
                    const Rule(),
                    const SizedBox(height: 14),
                  ],
                  if (_pages.isNotEmpty)
                    Expanded(child: Text(_pages[_page], style: st.text(st.base, height: 1.6), overflow: TextOverflow.clip)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(kPadH, 8, kPadH, 12 + MediaQuery.of(ctx).padding.bottom),
            child: Row(children: [
              T('‹', size: st.small, color: _page > 0 ? st.dim : Colors.transparent),
              Expanded(child: T(_pages.isEmpty ? '' : '${_page + 1} / ${_pages.length}', size: st.small, color: st.dim, align: TextAlign.center)),
              T('›', size: st.small, color: _page < last ? st.dim : Colors.transparent),
            ]),
          ),
        ]),
      );
    });
  }
}
