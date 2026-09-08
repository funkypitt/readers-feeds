import 'package:flutter/material.dart';
import '../ui/l10n.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/bookmark_provider.dart';
import '../ui/reader_ui.dart';
import 'article_list.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>().bookmarks;
    final articles = bookmarks
        .map((b) => Article(id: b.articleId, title: b.title, link: b.link, sourceName: b.sourceName, sourceId: '', lang: '', publishedAt: b.bookmarkedAt))
        .toList();
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(t('saved for later'), onBack: () => Navigator.pop(context)),
        Expanded(child: ArticleList(articles: articles, empty: t('nothing saved. Long-press an article to keep it here for 90 days.'))),
      ]),
    );
  }
}
