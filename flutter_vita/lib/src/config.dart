import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bounce.dart';
import 'fallbacks/image_picker.dart';
import 'fallbacks/share.dart';
import 'fallbacks/url_launcher.dart';
import 'focus.dart';

/// The debug strip over the top of the screen, in a debug build.
enum DebugStrip {
  /// Built in, hidden until L+R+SELECT. The default with this package.
  shortcut,

  /// Shown from the first frame.
  always,

  /// Never drawn.
  hidden,
}

/// What the pad does to the app.
enum PadMode {
  /// Nothing; the app reads the pad itself if it wants it.
  none,

  /// The D-pad and the left stick move the focus, X activates, O goes back.
  /// Buttons, tiles and fields are reachable with no app code.
  focus,

  /// The left stick moves an arrow, X presses. A mouse, drawn by the
  /// embedder over every frame.
  cursor,
}

/// What the rear touch panel does.
enum RearTouch {
  none,

  /// A trackpad: a finger on the back scrolls what is under the cursor, or
  /// under the last front touch.
  scroll,
}

/// The console's clocks.
enum CpuClock {
  /// 333 MHz, the console's default.
  normal,

  /// 444 MHz with the bus and GPU raised to match; the most user mode gets.
  /// More frames, less battery.
  high,
}

/// What `SystemNavigator.pop()` and `exitApplication` do.
enum ExitBehaviour {
  /// The receiver in a debug build, the LiveArea in a release build.
  auto,

  /// Hand the console to the receiver (debug builds; a release build leaves).
  handoff,

  /// Leave to the LiveArea.
  exit,

  /// Stay.
  ignore,
}

/// The PS button.
enum PsButton {
  /// The shell's: it suspends the app and opens the LiveArea.
  system,

  /// Locked while the app runs (a kiosk, a game). L+R+START still hands off
  /// in a debug build, and the lock falls with the process.
  locked,
}

/// Plugins the console has no side for, answered in Dart by this package so
/// the app keeps the code it wrote for phones.
enum Fallback {
  /// `share_plus`: text and files are saved to `ux0:data/<title id>/shared/`
  /// and a toast says so.
  share,

  /// `url_launcher` without `url_launcher_vita`: web links open the console's
  /// browser; a mail address or a phone number is shown with a Copy button.
  urlLauncher,

  /// `image_picker`: the file browser over `ux0:picture/` and `ux0:video/`.
  imagePicker,
}

/// The console and this build, as `FlutterVita.info()` answers.
class VitaInfo {
  const VitaInfo(this._m);
  final Map<Object?, Object?> _m;

  String get titleId => _m['titleId'] as String? ?? '';
  String get engineRevision => _m['engineRevision'] as String? ?? '';
  String get flutterVersion => _m['flutterVersion'] as String? ?? '';
  String get embedderVersion => _m['embedderVersion'] as String? ?? '';
  bool get release => _m['release'] == true;
  String get backend => _m['backend'] as String? ?? '';
  double get pixelRatio => (_m['pixelRatio'] as num?)?.toDouble() ?? 1.0;
  int get batteryPercent => (_m['batteryPercent'] as num?)?.toInt() ?? -1;
  bool get charging => _m['charging'] == true;
  int get freeMemoryK => (_m['freeMemoryK'] as num?)?.toInt() ?? -1;
  int get freeCdramK => (_m['freeCdramK'] as num?)?.toInt() ?? -1;
  int get armMhz => (_m['armMhz'] as num?)?.toInt() ?? -1;
  int get gpuMhz => (_m['gpuMhz'] as num?)?.toInt() ?? -1;

  @override
  String toString() => 'VitaInfo($_m)';
}

enum VitaLogLevel { debug, info, warning, error }

/// One call at start-up, and the app behaves like a console app.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await FlutterVita.configure(
///     pad: PadMode.focus,
///     rearTouch: RearTouch.scroll,
///     pixelRatio: 1.5,
///     fallbacks: {Fallback.share, Fallback.urlLauncher},
///   );
///   runApp(const MyApp());
/// }
/// ```
///
/// Every argument is optional and every call is a delta: `configure(pad:
/// PadMode.cursor)` later changes the pad and nothing else. On any other
/// platform every call does nothing, so the same `main` runs on the desktop.
///
/// What a *build* decides is not here: the title id, the LiveArea, the heap
/// and `--release` (no dev server, no strip) are the pubspec's `vita:` block
/// and the `flutter-vita build` flags.
abstract final class FlutterVita {
  static const _channel = MethodChannel('vita/config', JSONMethodCodec());
  static VitaInfo? _info;
  static final Set<Fallback> _fallbacks = {};

  static Future<void> configure({
    DebugStrip? debugStrip,
    bool? keepAwake,
    bool? watchdog,
    double? pixelRatio,
    PadMode? pad,
    RearTouch? rearTouch,
    CpuClock? cpuClock,
    ExitBehaviour? onExit,
    PsButton? psButton,
    Set<Fallback>? fallbacks,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final args = <String, Object?>{};
    if (debugStrip != null) {
      args['debugStrip'] = switch (debugStrip) {
        DebugStrip.shortcut => 2,
        DebugStrip.always => 1,
        DebugStrip.hidden => 0,
      };
    }
    if (keepAwake != null) args['keepAwake'] = keepAwake;
    if (watchdog != null) args['watchdog'] = watchdog;
    if (pixelRatio != null) args['pixelRatio'] = pixelRatio;
    if (pad != null) {
      if (pad == PadMode.focus) {
        PadFocus.start();
      } else {
        PadFocus.stop();
      }
      args['pad'] = pad.name;
    }
    if (rearTouch != null) args['rearTouch'] = rearTouch.name;
    if (cpuClock != null) args['cpuClock'] = cpuClock.name;
    if (onExit != null) args['onExit'] = onExit.name;
    if (psButton != null) args['psButton'] = psButton.name;
    if (fallbacks != null) {
      await _setFallbacks(fallbacks);
      args['bounce'] = Bounce.channels;
    }
    if (args.isEmpty) return;
    await _send('configure', args);
  }

  static Future<void> _setFallbacks(Set<Fallback> wanted) async {
    for (final f in Fallback.values) {
      final channel = switch (f) {
        Fallback.share => ShareFallback.channel,
        Fallback.urlLauncher => UrlLauncherFallback.channel,
        Fallback.imagePicker => ImagePickerFallback.channel,
      };
      if (wanted.contains(f) && !_fallbacks.contains(f)) {
        switch (f) {
          case Fallback.share:
            final titleId = (await info())?.titleId ?? 'flutter-vita';
            Bounce.register(channel, ShareFallback(titleId).call);
          case Fallback.urlLauncher:
            Bounce.register(channel, UrlLauncherFallback().call);
          case Fallback.imagePicker:
            Bounce.register(channel, ImagePickerFallback().call);
        }
        _fallbacks.add(f);
      } else if (!wanted.contains(f) && _fallbacks.contains(f)) {
        Bounce.unregister(channel);
        _fallbacks.remove(f);
      }
    }
  }

  /// The console and this build. Null anywhere but on a Vita.
  static Future<VitaInfo?> info({bool refresh = false}) async {
    if (_info != null && !refresh) return _info;
    final r = await _send<Map<Object?, Object?>>('info', null);
    if (r == null) return null;
    return _info = VitaInfo(r);
  }

  /// A line in the console's log (`flutter-vita logs`), prefixed `app:`.
  static Future<void> log(String message,
      {VitaLogLevel level = VitaLogLevel.info}) {
    return _send('log', {'level': level.name, 'message': message});
  }

  static Future<T?> _send<T>(String method, Object? args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      // Not a Vita: the desktop run of the same app.
      return null;
    }
  }
}
