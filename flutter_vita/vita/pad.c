// The controller, for flutter_vita: `vita/pad`.
//
//   read                    the buttons and sticks now
//   waitChord {mask, ms}    returns when every button in `mask` is down
//                           (after they were all up first), or after `ms`
//   waitNav {ms}            returns on the next navigation event: a button
//                           going down, or the left stick tilted past its
//                           dead zone (reported as the D-pad direction, with
//                           key repeat while it stays tilted), or after `ms`
//
// Each wait is one thread parked on a poll instead of a Dart timer asking the
// channel many times a second: the registry gives a call up to 15 s, so the
// Dart side asks for 14 s at a time and one thread serves the whole app.
#include <fvita_plugin.h>

#include <psp2/ctrl.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>

#include <string.h>

// The debug strip's default with this package: built in, hidden until
// L+R+SELECT. FlutterVita.configure(debugStrip: ...) changes it at run time;
// a release build zeroes it whatever is said here (flutter_vita_release).
int flutter_vita_debug_overlay = 2;

static unsigned buttons_now(SceCtrlData* pad) {
  memset(pad, 0, sizeof *pad);
  sceCtrlPeekBufferPositive(0, pad, 1);
  return pad->buttons;
}

// The left stick as a direction, or 0.
static unsigned stick_dir(const SceCtrlData* pad) {
  const int x = (int)pad->lx - 128, y = (int)pad->ly - 128;
  const int dz = 60;
  if (x > -dz && x < dz && y > -dz && y < dz) return 0;
  if ((x < 0 ? -x : x) > (y < 0 ? -y : y)) return x < 0 ? SCE_CTRL_LEFT : SCE_CTRL_RIGHT;
  return y < 0 ? SCE_CTRL_UP : SCE_CTRL_DOWN;
}

static int handle(const char* method, const char* body, size_t len, char* out, size_t cap) {
  if (strcmp(method, "read") == 0) {
    SceCtrlData pad;
    const unsigned b = buttons_now(&pad);
    return fvita_reply_ok(out, cap, "{\"buttons\":%u,\"lx\":%u,\"ly\":%u,\"rx\":%u,\"ry\":%u}", b, pad.lx, pad.ly,
                          pad.rx, pad.ry);
  }
  if (strcmp(method, "waitChord") == 0) {
    const unsigned mask = (unsigned)fvita_json_int(body, len, "mask", 0);
    int ms = fvita_json_int(body, len, "ms", 14000);
    if (ms < 30) ms = 30;
    if (ms > 14000) ms = 14000;
    if (mask == 0) return fvita_reply_err(out, cap, "args", "mask is 0", 0);
    const SceUInt64 end = sceKernelGetProcessTimeWide() + (SceUInt64)ms * 1000;
    SceCtrlData pad;
    int released = (buttons_now(&pad) & mask) != mask;
    while (sceKernelGetProcessTimeWide() < end) {
      const unsigned b = buttons_now(&pad);
      if ((b & mask) == mask) {
        if (released) return fvita_reply_ok(out, cap, "{\"pressed\":true,\"buttons\":%u}", b);
      } else {
        released = 1;
      }
      sceKernelDelayThread(30 * 1000);
    }
    return fvita_reply_ok(out, cap, "{\"pressed\":false,\"buttons\":%u}", pad.buttons);
  }
  if (strcmp(method, "waitNav") == 0) {
    int ms = fvita_json_int(body, len, "ms", 14000);
    if (ms < 16) ms = 16;
    if (ms > 14000) ms = 14000;
    const SceUInt64 end = sceKernelGetProcessTimeWide() + (SceUInt64)ms * 1000;
    SceCtrlData pad;
    unsigned prev = buttons_now(&pad);
    unsigned prev_dir = stick_dir(&pad);
    // A direction held down repeats: 400 ms, then every 120 ms. The D-pad and
    // the stick share one timer, so switching between them does not stutter.
    unsigned held = prev & (SCE_CTRL_UP | SCE_CTRL_DOWN | SCE_CTRL_LEFT | SCE_CTRL_RIGHT);
    if (held == 0) held = prev_dir;
    SceUInt64 repeat_at = held != 0 ? sceKernelGetProcessTimeWide() + 400 * 1000 : 0;
    while (sceKernelGetProcessTimeWide() < end) {
      sceKernelDelayThread(16 * 1000);
      const unsigned b = buttons_now(&pad);
      const unsigned dir = stick_dir(&pad);
      unsigned pressed = b & ~prev;                        // buttons that went down
      if (dir != 0 && dir != prev_dir) pressed |= dir;     // the stick tilted (or turned)
      prev = b;
      prev_dir = dir;
      unsigned now_held = b & (SCE_CTRL_UP | SCE_CTRL_DOWN | SCE_CTRL_LEFT | SCE_CTRL_RIGHT);
      if (now_held == 0) now_held = dir;
      const SceUInt64 now = sceKernelGetProcessTimeWide();
      if (now_held == 0) {
        repeat_at = 0;
      } else if (pressed & now_held) {
        repeat_at = now + 400 * 1000;
      } else if (repeat_at != 0 && now >= repeat_at) {
        pressed |= now_held;
        repeat_at = now + 120 * 1000;
      } else if (repeat_at == 0) {
        repeat_at = now + 400 * 1000;
      }
      if (pressed != 0) {
        return fvita_reply_ok(out, cap, "{\"pressed\":%u,\"buttons\":%u,\"lx\":%u,\"ly\":%u}", pressed, b,
                              pad.lx, pad.ly);
      }
    }
    return fvita_reply_ok(out, cap, "{\"pressed\":0,\"buttons\":%u,\"lx\":%u,\"ly\":%u}", pad.buttons, pad.lx,
                          pad.ly);
  }
  return fvita_reply_err(out, cap, "unknown", method, 0);
}

__attribute__((constructor)) static void reg(void) { fvita_channel_register("vita/pad", handle); }
