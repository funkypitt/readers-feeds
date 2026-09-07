import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/source_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SourceProvider()..load()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: const ReadersFeedsApp(),
    ),
  );
}

class ReadersFeedsApp extends StatelessWidget {
  const ReadersFeedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<SettingsProvider>().dark;
    final bg = dark ? Colors.black : Colors.white;
    final fg = dark ? Colors.white : Colors.black;
    return MaterialApp(
      title: "Reader's Feeds",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        canvasColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: fg, brightness: dark ? Brightness.dark : Brightness.light, surface: bg, onSurface: fg, primary: fg, onPrimary: bg),
        fontFamily: null,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        textSelectionTheme: TextSelectionThemeData(cursorColor: fg, selectionColor: fg.withValues(alpha: 0.25), selectionHandleColor: fg),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()}),
      ),
      home: const FeedScreen(),
    );
  }
}
