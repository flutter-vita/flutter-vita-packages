import 'package:flutter/services.dart';
import 'package:vita_file_browser/vita_file_browser.dart';

import '../bounce.dart';

/// `image_picker` without a gallery app: the console's photos are files
/// under `ux0:picture/` and its videos under `ux0:video/`, so the picker is
/// the file browser over those, filtered by extension. The camera source
/// answers "cancelled": a live camera picker is `camera_vita`'s business.
class ImagePickerFallback {
  static const channel = 'plugins.flutter.io/image_picker';

  static const _images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
  static const _videos = ['mp4', 'm4v', 'mov'];

  Future<ByteData?> call(ByteData? message) async {
    if (message == null) return null;
    final MethodCall call;
    try {
      call = standardCodec.decodeMethodCall(message);
    } on Object {
      return null;
    }
    final args = call.arguments is Map ? call.arguments as Map : const {};
    // 0 is the camera, 1 the gallery, in image_picker's ImageSource order.
    final source = (args['source'] as num?)?.toInt() ?? 1;
    switch (call.method) {
      case 'pickImage':
        if (source == 0) return standardCodec.encodeSuccessEnvelope(null);
        final paths =
            await _browse(_images, 'ux0:picture/', false, 'Pick a photo');
        return standardCodec.encodeSuccessEnvelope(paths?.firstOrNull);
      case 'pickMultiImage':
        final paths =
            await _browse(_images, 'ux0:picture/', true, 'Pick photos');
        return standardCodec.encodeSuccessEnvelope(paths ?? const <String>[]);
      case 'pickVideo':
        if (source == 0) return standardCodec.encodeSuccessEnvelope(null);
        final paths =
            await _browse(_videos, 'ux0:video/', false, 'Pick a video');
        return standardCodec.encodeSuccessEnvelope(paths?.firstOrNull);
      case 'pickMedia':
      case 'pickMultipleMedia':
        final multiple =
            call.method == 'pickMultipleMedia' || args['allowMultiple'] == true;
        final paths = await _browse(
            [..._images, ..._videos], 'ux0:picture/', multiple, 'Pick media');
        return standardCodec.encodeSuccessEnvelope(paths ?? const <String>[]);
      case 'retrieve':
        // Android's lost-data recovery; nothing was ever lost here.
        return standardCodec.encodeSuccessEnvelope(null);
      default:
        return standardCodec.encodeErrorEnvelope(
            code: 'unimplemented', message: call.method);
    }
  }

  Future<List<String>?> _browse(
          List<String> extensions, String start, bool multiple, String title) =>
      browseForPaths(
        mode: FileBrowserMode.openFile,
        title: title,
        allowedExtensions: extensions,
        allowMultiple: multiple,
        initialDirectory: start,
      );
}
