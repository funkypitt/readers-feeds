// An export is first saved where the person chooses, then a menu offers to share the same
// file (Telegram, kDrive, e-mail…). The shared copy lives in the cache, under [cacheDir].
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'l10n.dart';
import 'reader_ui.dart';

/// Saves [text] as [name] through the system's save dialog; on success, shows "saved as <name>"
/// with a "share this file…" entry. Nothing happens when the dialog is cancelled.
Future<void> saveThenOfferShare(BuildContext context, {required String name, required String text, required String mime, String? subject, String cacheDir = 'exports'}) async {
  final bytes = Uint8List.fromList(utf8.encode(text));
  final ext = name.split('.').last;
  final saved = await FilePicker.platform.saveFile(fileName: name, bytes: bytes, type: FileType.custom, allowedExtensions: [ext]);
  if (saved == null || !context.mounted) return;
  await showTextMenu(context, title: t('saved as %1', [name]), items: [
    MenuItemText(t('share this file…'), () async {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/$cacheDir');
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: mime, name: name)], subject: subject);
    }),
  ]);
}
