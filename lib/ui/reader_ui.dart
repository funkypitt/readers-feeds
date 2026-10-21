// The Reader's look, shared by every screen: a background, a text colour and an accent for the
// inverted rows, one light sans face, text rows separated by hairlines, menus and prompts that
// are also plain text. With a colour palette, the rows, menus and prompts become rounded cards
// (tiles); the two inks stay text on the page.
import 'package:flutter/material.dart';
import 'l10n.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ReaderStyle {
  final Color bg;
  final Color fg;
  /// Fills the inverted rows (the text colour itself in the two inks); [onAccent] is written on it.
  final Color accent;
  final Color onAccent;
  /// The card under a tappable row, a second dimmer surface, the card while the finger is on
  /// it; the inks have none ([tiles] false: text on the page).
  final Color tile;
  final Color tile2;
  final Color press;
  final bool tiles;
  final double base; // the reading size; everything else derives from it
  final bool serif;
  const ReaderStyle({required this.bg, required this.fg, required this.accent, required this.onAccent, required this.tile, required this.tile2, required this.press, required this.tiles, required this.base, required this.serif});

  Color get dim => fg.withValues(alpha: 0.55);
  Color get rule => fg.withValues(alpha: 0.25);
  /// From the background's luminance: the status-bar icons depend on it.
  bool get isDark => bg.computeLuminance() < 0.5;
  double get menu => base + 8; // menu entries
  double get title => base + 3; // article titles, screen titles
  double get small => base - 3; // secondary lines
  double get big => base * 2.2;
  // Explicit face and spacing: the widget and the measuring painter must wrap identically.
  String get family => serif ? t('serif') : 'Roboto';

  TextStyle text(double size, {Color? color, double height = 1.25, FontWeight weight = FontWeight.w300}) =>
      TextStyle(fontSize: size, color: color ?? fg, height: height, fontWeight: weight, fontFamily: family, letterSpacing: 0, wordSpacing: 0, decoration: TextDecoration.none, leadingDistribution: TextLeadingDistribution.even);

  static ReaderStyle of(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final p = s.palette;
    return ReaderStyle(
      bg: p.bg,
      fg: p.fg,
      accent: p.accent,
      onAccent: p.onAccent,
      tile: p.tile,
      tile2: p.tile2,
      press: p.press,
      tiles: p.tiles,
      base: s.fontSize,
      serif: s.serif,
    );
  }
}

const double kPadH = 28;
const double kPadV = 18;

/// Tiles: the margin around a card, its corner.
const double kTileGap = 12;
const double kTileCorner = 18;

/// True inside a sheet or a card: the rows in it are flat, the card is the surface.
class InTile extends InheritedWidget {
  const InTile({super.key, required super.child});
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InTile>() != null;
  @override
  bool updateShouldNotify(InTile oldWidget) => false;
}

/// The card of a hand-made tappable block (not a TextRow): margin, rounded corners, surface;
/// nothing in the inks, nothing inside a sheet.
class TileCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double vertical;
  const TileCard({super.key, required this.child, this.color, this.vertical = 4});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    if (!st.tiles || InTile.of(context)) return child;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kTileGap, vertical: vertical),
      child: ClipRRect(borderRadius: BorderRadius.circular(kTileCorner), child: ColoredBox(color: color ?? st.tile, child: child)),
    );
  }
}

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

/// Hairline rule in the foreground colour; with tiles, the rows are set apart by space instead.
class Rule extends StatelessWidget {
  const Rule({super.key});
  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    if (st.tiles) return const SizedBox(height: 4);
    return Container(height: 1, color: st.rule);
  }
}

/// One line of text you can tap, with an optional dim second line. Inverted = selected.
/// With tiles, a rounded card on the page (flat inside a sheet), the press colour under the finger.
class TextRow extends StatefulWidget {
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
  State<TextRow> createState() => _TextRowState();
}

class _TextRowState extends State<TextRow> {
  bool _pressed = false;
  void _press(bool v) { if (_pressed != v) setState(() => _pressed = v); }

  @override
  Widget build(BuildContext context) {
    final st = ReaderStyle.of(context);
    final inverted = widget.inverted;
    final tappable = widget.onTap != null || widget.onLongPress != null;
    final inTile = InTile.of(context);
    final card = st.tiles && !inTile;
    final fg = inverted ? st.onAccent : (widget.dim ? st.dim : st.fg);
    final Color? bg = inverted ? st.accent : (st.tiles && _pressed && tappable) ? st.press : (card ? st.tile : null);
    // a card: outer margin, rounded, then the same text inset as the page's free text
    Widget body = Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: card ? kPadH - kTileGap : kPadH, vertical: kPadV * 0.7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T(widget.text, size: widget.size ?? st.title, color: fg, maxLines: widget.maxLines),
        if (widget.secondary != null) T(widget.secondary!, size: st.small, color: inverted ? st.onAccent.withValues(alpha: 0.7) : st.dim, maxLines: widget.secondaryLines),
      ]),
    );
    if (card) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: kTileGap, vertical: 4),
        child: ClipRRect(borderRadius: BorderRadius.circular(kTileCorner), child: body),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: st.tiles && tappable ? (_) => _press(true) : null,
      onTapUp: st.tiles && tappable ? (_) => _press(false) : null,
      onTapCancel: st.tiles && tappable ? () => _press(false) : null,
      onLongPressEnd: st.tiles && tappable ? (_) => _press(false) : null,
      child: body,
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
        statusBarIconBrightness: st.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: st.bg,
        systemNavigationBarIconBrightness: st.isDark ? Brightness.light : Brightness.dark,
      ),
      // a Scaffold, so that say() has somewhere to show its line
      child: Scaffold(backgroundColor: st.bg, resizeToAvoidBottomInset: false, body: SafeArea(bottom: false, child: child)),
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
    barrierColor: settings.palette.bg.withValues(alpha: 0.6),
    isScrollControlled: true,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: settings,
      child: Builder(builder: (ctx) {
        final st = ReaderStyle.of(ctx);
        final tiles = st.tiles;
        // tiles: a rounded card in the tile colour, its rows flat; the inks: the page with a rule on top
        final sheet = Container(
          decoration: tiles
              ? BoxDecoration(color: st.tile, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)))
              : BoxDecoration(color: st.bg, border: Border(top: BorderSide(color: st.fg, width: 1))),
          clipBehavior: tiles ? Clip.antiAlias : Clip.none,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (tiles) const SizedBox(height: 10),
                if (title != null) Padding(padding: const EdgeInsets.fromLTRB(kPadH, kPadV, kPadH, 4), child: T(title, size: st.small, color: st.dim, maxLines: 2)),
                for (final it in items) TextRow(it.text, size: st.menu, inverted: it.inverted, maxLines: 1, onTap: () { Navigator.pop(ctx); it.onTap(); }),
                if (footer.isNotEmpty) ...[
                  // tiles: a hairline in the pressed colour, where the inks draw a rule
                  if (tiles) ...[if (items.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: kPadH, vertical: 6), child: Container(height: 1, color: st.press))]
                  else const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Rule()),
                  for (final it in footer) TextRow(it.text, size: st.title, dim: true, maxLines: 1, onTap: () { Navigator.pop(ctx); it.onTap(); }),
                ],
                const SizedBox(height: 12),
              ]),
            ),
          ),
        );
        return InTile(child: tiles ? Padding(padding: const EdgeInsets.symmetric(horizontal: kTileGap), child: sheet) : sheet);
      }),
    ),
  );
}

/// A question and a line to type in. Returns null when cancelled.
Future<String?> textPrompt(BuildContext context, String title, {String initial = '', String hint = '', String? ok, TextInputType? keyboard, bool obscure = false}) {
  final settings = context.read<SettingsProvider>();
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    barrierColor: settings.palette.bg.withValues(alpha: 0.6),
    builder: (ctx) => ChangeNotifierProvider.value(
      value: settings,
      child: Builder(builder: (ctx) {
        final st = ReaderStyle.of(ctx);
        // tiles: a rounded card in the tile colour; the inks: the page framed by a hairline
        return InTile(child: Dialog(
          backgroundColor: st.tiles ? st.tile : st.bg,
          shape: st.tiles
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
              : RoundedRectangleBorder(side: BorderSide(color: st.fg), borderRadius: BorderRadius.zero),
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
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(ctx), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: T(t('cancel'), size: st.title))),
                const SizedBox(width: 36),
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(ctx, ctrl.text), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: T(ok ?? t('ok'), size: st.title))),
              ]),
            ]),
          ),
        ));
      }),
    ),
  );
}

/// Word-of-mouth feedback instead of a snackbar: an inverted line, in the accent.
void say(BuildContext context, String text) {
  final st = ReaderStyle.of(context);
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(text, style: st.text(st.small, color: st.onAccent)),
    backgroundColor: st.accent,
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

String timeAgo(DateTime? time) {
  if (time == null) return '';
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return t('now');
  if (d.inMinutes < 60) return t('%1 min', [d.inMinutes]);
  if (d.inHours < 24) return t('%1 h', [d.inHours]);
  if (d.inDays < 7) return t('%1 d', [d.inDays]);
  return '${time.day}.${time.month}.${time.year}';
}
