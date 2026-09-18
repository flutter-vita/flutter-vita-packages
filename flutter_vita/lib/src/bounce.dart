import 'dart:convert';

import 'package:flutter/services.dart';

/// A handler for a platform channel answered in Dart: the message as the
/// plugin encoded it, the reply as the plugin expects it.
typedef BounceHandler = Future<ByteData?> Function(ByteData? message);

/// The Dart end of the embedder's bounce.
///
/// A plugin calls its method channel; the embedder has no C for it; so the
/// embedder wraps the raw message and sends it up on `vita/bounce`, and the
/// reply from here goes back on the plugin's own response handle. The plugin
/// never learns that its platform side was Dart. One byte of channel-name
/// length, the name, then the message, is the frame.
abstract final class Bounce {
  static final Map<String, BounceHandler> _handlers = {};
  static bool _installed = false;

  static void register(String channel, BounceHandler handler) {
    _handlers[channel] = handler;
    _install();
  }

  static void unregister(String channel) => _handlers.remove(channel);

  /// The channels the embedder must bounce, for `configure`. The keyboard's
  /// channel is switched by its own key and is not in this list.
  static List<String> get channels => [
        for (final c in _handlers.keys)
          if (c != 'flutter/textinput') c,
      ];

  static void _install() {
    if (_installed) return;
    _installed = true;
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      'vita/bounce',
      (ByteData? frame) async {
        if (frame == null || frame.lengthInBytes < 1) return null;
        final bytes =
            frame.buffer.asUint8List(frame.offsetInBytes, frame.lengthInBytes);
        final n = bytes[0];
        if (bytes.length < 1 + n) return null;
        final channel = utf8.decode(bytes.sublist(1, 1 + n));
        final inner = ByteData.sublistView(bytes, 1 + n);
        final handler = _handlers[channel];
        if (handler == null) return null;
        return handler(inner);
      },
    );
  }
}

/// The two codecs the fallbacks meet: every federated plugin uses the
/// standard one, the framework's own channels the JSON one.
const StandardMethodCodec standardCodec = StandardMethodCodec();
const JSONMethodCodec jsonCodec = JSONMethodCodec();
