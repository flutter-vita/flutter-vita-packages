import 'package:flutter/services.dart';

import '../bounce.dart';
import '../ui.dart';

/// `url_launcher` without `url_launcher_vita`: a web link opens the console's
/// browser through the embedder's `vita/browser` channel; a mail address or a
/// phone number, which no app on the console can take, is shown in a dialog
/// with a Copy button. Both count as launched, so an app that hides its
/// buttons behind `canLaunchUrl` keeps them.
class UrlLauncherFallback {
  static const channel = 'plugins.flutter.io/url_launcher';
  static const _browser = MethodChannel('vita/browser', JSONMethodCodec());

  Future<ByteData?> call(ByteData? message) async {
    if (message == null) return null;
    final MethodCall call;
    try {
      call = standardCodec.decodeMethodCall(message);
    } on Object {
      return null;
    }
    final args = call.arguments is Map ? call.arguments as Map : const {};
    final url = (args['url'] as String?) ?? '';
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
    switch (call.method) {
      case 'canLaunch':
        return standardCodec.encodeSuccessEnvelope(_known(scheme));
      case 'launch':
        return standardCodec.encodeSuccessEnvelope(await _launch(url, scheme));
      case 'closeWebView':
        return standardCodec.encodeSuccessEnvelope(null);
      case 'supportsMode':
      case 'supportsCloseForMode':
        return standardCodec.encodeSuccessEnvelope(false);
      default:
        return standardCodec.encodeErrorEnvelope(
            code: 'unimplemented', message: call.method);
    }
  }

  bool _known(String scheme) =>
      const {'http', 'https', 'mailto', 'tel', 'sms'}.contains(scheme);

  Future<bool> _launch(String url, String scheme) async {
    switch (scheme) {
      case 'http':
      case 'https':
        try {
          final ok = await _browser.invokeMethod<bool>('launch', {'url': url});
          return ok ?? false;
        } on PlatformException {
          return false;
        } on MissingPluginException {
          return false;
        }
      case 'mailto':
        final uri = Uri.parse(url);
        final address = uri.path;
        await showInfoDialog('Mail address', address, copyText: address);
        return true;
      case 'tel':
      case 'sms':
        final number = Uri.parse(url).path;
        await showInfoDialog(
            scheme == 'tel' ? 'Phone number' : 'SMS number', number,
            copyText: number);
        return true;
      default:
        return false;
    }
  }
}
