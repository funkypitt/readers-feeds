import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../ui/reader_ui.dart';

class SubstackLoginScreen extends StatefulWidget {
  const SubstackLoginScreen({super.key});

  @override
  State<SubstackLoginScreen> createState() => _SubstackLoginScreenState();
}

class _SubstackLoginScreenState extends State<SubstackLoginScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _tryExtractCookie(),
        onProgress: (progress) {
          if (progress == 100 && _loading) {
            setState(() => _loading = false);
          }
        },
      ))
      ..loadRequest(Uri.parse('https://substack.com/sign-in'));
  }

  Future<void> _tryExtractCookie() async {
    try {
      final cookies = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      final cookieStr = cookies.toString().replaceAll('"', '');
      final match = RegExp(r'substack\.sid=([^;]+)').firstMatch(cookieStr);
      if (match != null && mounted) {
        final sid = match.group(1)!;
        Navigator.pop(context, sid);
      }
    } catch (_) {
      // JS extraction failed (HttpOnly cookie) — user can use paste fallback
    }
  }

  Future<void> _paste() async {
    final value = await textPrompt(context, 'the substack.sid cookie is HttpOnly and cannot be read from the page. In a desktop browser: DevTools › Application › Cookies › substack.sid, paste its value here.', hint: 'substack.sid', ok: 'save');
    if (value != null && value.trim().isNotEmpty && mounted) Navigator.pop(context, value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ReaderPage(
      child: Column(children: [
        ScreenTitle(_loading ? 'Substack sign-in · …' : 'Substack sign-in', onBack: () => Navigator.pop(context), trailing: 'paste', onTrailing: _paste),
        Expanded(child: WebViewWidget(controller: _controller)),
      ]),
    );
  }
}
