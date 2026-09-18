import 'dart:io';

import 'package:flutter/services.dart';

import '../bounce.dart';
import '../ui.dart';

/// `share_plus` without a share sheet: the console has no other app to hand
/// text or a file to. What it has is the memory card. Text and files go to
/// `ux0:data/<title id>/shared/`, a toast says so, and the plugin gets the
/// success it expects. The user copies the file off with VitaShell or the
/// receiver's FILES tab.
class ShareFallback {
  ShareFallback(this.titleId);
  final String titleId;

  static const channel = 'dev.fluttercommunity.plus/share';

  String get directory => 'ux0:data/$titleId/shared';

  Future<ByteData?> call(ByteData? message) async {
    if (message == null) return null;
    final MethodCall call;
    try {
      call = standardCodec.decodeMethodCall(message);
    } on Object {
      return null;
    }
    if (!call.method.startsWith('share')) {
      return standardCodec.encodeErrorEnvelope(
          code: 'unimplemented', message: call.method);
    }
    final args = call.arguments is Map ? call.arguments as Map : const {};
    final text = args['text'] as String?;
    final subject = args['subject'] as String?;
    final uri = args['uri'] as String?;
    final paths = <String>[
      for (final p in (args['paths'] as List?) ?? const [])
        if (p is String) p,
      for (final p in (args['uris'] as List?) ?? const [])
        if (p is String) p,
    ];

    final saved = <String>[];
    try {
      final dir = Directory(directory);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      if ((text != null && text.isNotEmpty) || uri != null) {
        final f = File('$directory/$stamp.txt');
        f.writeAsStringSync([
          if (subject != null) subject,
          if (text != null) text,
          if (uri != null) uri,
        ].join('\n'));
        saved.add(f.path);
      }
      for (final p in paths) {
        final src = File(p);
        if (!src.existsSync()) continue;
        final name = p.split('/').last;
        final dst = File('$directory/$stamp-$name');
        src.copySync(dst.path);
        saved.add(dst.path);
      }
    } on FileSystemException catch (e) {
      showToast('Share failed: ${e.message}');
      return standardCodec.encodeErrorEnvelope(
          code: 'share_failed', message: e.message);
    }
    showToast(saved.isEmpty
        ? 'Nothing to share'
        : 'Saved to $directory (${saved.length})');
    // share_plus's *WithResult methods want a string; the older ones ignore
    // the reply. One answer serves both.
    return standardCodec
        .encodeSuccessEnvelope('dev.fluttercommunity.plus/share/success');
  }
}
