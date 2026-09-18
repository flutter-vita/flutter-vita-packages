import 'dart:async';

import 'package:flutter/material.dart';

import 'pad.dart';
import 'ui.dart';

/// `pad: focus`: the D-pad and the left stick move Flutter's focus, X
/// activates, O dismisses or goes back.
///
/// Dart only. The framework already knows how to move focus in a direction
/// (that is what the arrow keys do on desktop) and how to activate the
/// focused widget; this turns pad events into those calls. No app code: a
/// button, a list tile or a text field is focusable as it is, and the focus
/// ring is shown because the highlight strategy is switched to the one a
/// keyboard gets.
abstract final class PadFocus {
  static StreamSubscription<VitaNavEvent>? _sub;

  static bool get on => _sub != null;

  static void start() {
    if (_sub != null) return;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    _sub = VitaPad.nav().listen(_handle);
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  }

  static void _handle(VitaNavEvent e) {
    final fm = FocusManager.instance;
    TraversalDirection? dir;
    if (e.pressed & VitaButtons.up != 0) dir = TraversalDirection.up;
    if (e.pressed & VitaButtons.down != 0) dir = TraversalDirection.down;
    if (e.pressed & VitaButtons.left != 0) dir = TraversalDirection.left;
    if (e.pressed & VitaButtons.right != 0) dir = TraversalDirection.right;
    if (dir != null) {
      final node = fm.primaryFocus;
      if (node == null || node == fm.rootScope || node is FocusScopeNode) {
        // Nothing has the focus yet: the first focusable widget gets it.
        (node ?? fm.rootScope).nextFocus();
      } else {
        node.focusInDirection(dir);
      }
      return;
    }
    if (e.pressed & VitaButtons.cross != 0) {
      final ctx = fm.primaryFocus?.context;
      if (ctx != null) {
        // What Enter and Space do on a keyboard: buttons, tiles, switches and
        // checkboxes all answer ActivateIntent.
        Actions.maybeInvoke(ctx, const ActivateIntent());
      }
      return;
    }
    if (e.pressed & VitaButtons.circle != 0) {
      final ctx = fm.primaryFocus?.context;
      // Escape first (closes a menu, a dialog, a search field), then the
      // back button's route pop.
      final dismissed = ctx != null &&
          Actions.maybeInvoke(ctx, const DismissIntent()) != null;
      if (!dismissed) rootNavigator()?.maybePop();
    }
  }
}
