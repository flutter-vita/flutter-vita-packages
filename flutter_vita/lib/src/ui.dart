import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vita_file_browser/vita_file_browser.dart';

/// The app's root navigator, found without being handed one, and the
/// overlay it owns. What the fallbacks and the keyboard draw into.
NavigatorState? rootNavigator() => findRootNavigator();

OverlayState? rootOverlay() => rootNavigator()?.overlay;

/// A line at the bottom of the screen for three seconds.
void showToast(String text) {
  final overlay = rootOverlay();
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: const Color(0xE6202124),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(seconds: 3), entry.remove);
}

/// A dialog with a title, a body and a Copy button, for the things a phone
/// would open an app for and the console cannot: a mail address, a phone
/// number. Resolves when it closes.
Future<void> showInfoDialog(String title, String body,
    {String? copyText}) async {
  final navigator = rootNavigator();
  if (navigator == null) return;
  await showDialog<void>(
    context: navigator.context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SelectableText(body),
      actions: [
        if (copyText != null)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyText));
              Navigator.of(context).pop();
              showToast('Copied');
            },
            child: const Text('Copy'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
