// The Reader's look, shared by every screen: two colours, one light sans face,
// text rows separated by hairlines, menus and prompts that are also plain text.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ReaderStyle {
  final Color bg;
  final Color fg;
  final double base; // the reading size; everything else derives from it
  final bool serif;
  const ReaderStyle({required this.bg, required this.fg, required this.base, required this.serif});

  Color get dim => fg.withValues(alpha: 0.55);
  Color get rule => fg.withValues(alpha: 0.25);
  double get tile => base + 8; // menu entries
  double get title => base + 3; // article titles, screen titles
  double get small => base - 3; // secondary lines
  double get big => base * 2.2;
  // Explicit face and spacing: the widget and the measuring painter must wrap identically.
  String get family => serif ? 'serif' : 'Roboto';

  TextStyle text(double size, {Color? color, double height = 1.25, FontWeight weight = FontWeight.w300}) =>
      TextStyle(fontSize: size, color: color ?? fg, height: height, fontWeight: weight, fontFamily: family, letterSpacing: 0, wordSpacing: 0, decoration: TextDecoration.none, leadingDistribution: TextLeadingDistribution.even);

  static ReaderStyle of(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return ReaderStyle(
      bg: s.dark ? Colors.black : Colors.white,
      fg: s.dark ? Colors.white : Colors.black,
      base: s.fontSize,
      serif: s.serif,
    );
  }
}

const double kPadH = 28;
const double kPadV = 18;

class T extends StatelessWidget {
  final String text;
  final double? size;
  final Color? color;
  final int? maxLines;
  final double height;
  final TextAlign align;
  const T(this.text, {super.key, this.size, this.color, this.maxLines, this.height = 1.25, this.align = TextAlign.start});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    return Text(text, maxLines: maxLines, overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
        textAlign: align, style: st.text(size ?? st.title, color: color, height: height));
  }
}

class Small extends StatelessWidget {
  final String text;
  final Color? color;
  final int? maxLines;
  const Small(this.text, {super.key, this.color, this.maxLines = 2});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    return T(text, size: st.small, color: color ?? st.dim, maxLines: maxLines);
  }
}

class Rule extends StatelessWidget {
  const Rule({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 1, color: ReaderStyle.of(context).rule);
}

/// One line of text you can tap, with an optional dim second line. Inverted = selected.
class TextRow extends StatelessWidget {
  final String text;
  final String? secondary;
  final bool inverted;
  final bool dim;
  final double? size;
  final int maxLines;
  final int secondaryLines;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const TextRow(this.text, {super.key, this.secondary, this.inverted = false, this.dim = false, this.size, this.maxLines = 2, this.secondaryLines = 1, this.onTap, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    final fg = inverted ? st.bg : (dim ? st.dim : st.fg);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        color: inverted ? st.fg : null,
        padding: const EdgeInsets.symmetric(horizontal: kPadH, vertical: kPadV * 0.7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          T(text, size: size ?? st.title, color: fg, maxLines: maxLines),
          if (secondary != null) T(secondary!, size: st.small, color: inverted ? st.bg.withValues(alpha: 0.7) : st.dim, maxLines: secondaryLines),
        ]),
      ),
    );
  }
}

/// The dim title line of every screen: ← back, the title, an optional trailing action word.
class ScreenTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final String? trailing;
  final VoidCallback? onTrailing;
  final VoidCallback? onTitle;
  const ScreenTitle(this.title, {super.key, this.onBack, this.trailing, this.onTrailing, this.onTitle});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPadH, vertical: kPadV),
        child: Row(children: [
          if (onBack != null)
            GestureDetector(behavior: HitTestBehavior.opaque, onTap: onBack, child: Padding(padding: const EdgeInsets.only(right: 20), child: T('←', size: st.title, color: st.dim))),
          Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTitle, child: T(title, size: st.title, color: st.dim, maxLines: 1))),
          if (trailing != null)
            GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTrailing, child: Padding(padding: const EdgeInsets.only(left: 20), child: T(trailing!, size: st.title))),
        ]),
      ),
      const Rule(),
    ]);
  }
}

/// The page: the background colour, the status-bar inset, nothing else.
class ReaderPage extends StatelessWidget {
  final Widget child;
  const ReaderPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: st.bg == Colors.black ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: st.bg,
        systemNavigationBarIconBrightness: st.bg == Colors.black ? Brightness.light : Brightness.dark,
      ),
      child: Material(color: st.bg, child: SafeArea(bottom: false, child: child)),
    );
  }
}

class MenuItemText {
  final String text;
  final bool inverted;
  final VoidCallback onTap;
  const MenuItemText(this.text, this.onTap, {this.inverted = false});
}

/// A menu is a sheet of words. [footer] holds the entries every menu shares.
Future<void> showTextMenu(BuildContext context, {String? title, required List<MenuItemText> items, List<MenuItemText> footer = const []}) {
  final settings = context.read<SettingsProvider>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: (settings.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
    isScrollControlled: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: settings,
      child: Builder(builder: (ctx) {
        final st = ReaderStyle.of(ctx);
        return Container(
          decoration: BoxDecoration(color: st.bg, border: Border(top: BorderSide(color: st.fg, width: 1))),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (title != null) Padding(padding: const EdgeInsets.fromLTRB(kPadH, kPadV, kPadH, 4), child: T(title, size: st.small, color: st.dim, maxLines: 2)),
                for (final it in items) TextRow(it.text, size: st.tile, inverted: it.inverted, maxLines: 1, onTap: () { Navigator.pop(ctx); it.onTap(); }),
                if (footer.isNotEmpty) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Rule()),
                  for (final it in footer) TextRow(it.text, size: st.title, dim: true, maxLines: 1, onTap: () { Navigator.pop(ctx); it.onTap(); }),
                ],
                const SizedBox(height: 12),
              ]),
            ),
          ),
        );
      }),
    ),
  );
}

/// A question and a line to type in. Returns null when cancelled.
Future<String?> textPrompt(BuildContext context, String title, {String initial = '', String hint = '', String ok = 'ok', TextInputType? keyboard, bool obscure = false}) {
  final settings = context.read<SettingsProvider>();
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    barrierColor: (settings.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
    builder: (ctx) => ChangeNotifierProvider.value(
      value: settings,
      child: Builder(builder: (ctx) {
        final st = ReaderStyle.of(ctx);
        return Dialog(
          backgroundColor: st.bg,
          shape: RoundedRectangleBorder(side: BorderSide(color: st.fg), borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kPadH, kPadV, kPadH, 8),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(title, size: st.small, color: st.dim),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: keyboard,
                obscureText: obscure,
                cursorColor: st.fg,
                style: st.text(st.title),
                decoration: InputDecoration(
                  hintText: hint, hintStyle: st.text(st.title, color: st.rule),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: st.rule)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: st.fg)),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              Row(children: [
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(ctx), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: T('cancel', size: st.title))),
                const SizedBox(width: 36),
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(ctx, ctrl.text), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: T(ok, size: st.title))),
              ]),
            ]),
          ),
        );
      }),
    ),
  );
}

/// Word-of-mouth feedback instead of a snackbar.
void say(BuildContext context, String text) {
  final st = ReaderStyle.of(context);
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(text, style: st.text(st.small, color: st.bg)),
    backgroundColor: st.fg,
    behavior: SnackBarBehavior.floating,
    shape: const RoundedRectangleBorder(),
    duration: const Duration(seconds: 3),
  ));
}

Route<R> readerRoute<R>(Widget page) => PageRouteBuilder<R>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  if (d.inDays < 7) return '${d.inDays} d';
  return '${t.day}.${t.month}.${t.year}';
}
