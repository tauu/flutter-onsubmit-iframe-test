// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

// This is identical to the function used by the flutter engine.
// https://github.com/flutter/engine/blob/fce95c01cffab4fa96619d9dea6c0db121fef236/lib/web_ui/lib/src/engine/safe_browser_api.dart#L94
//
// This function is used in by the flutter engine in mobile web environments to
// decide how to handle blur events on input fields used for text editing.
// iOS:
// https://github.com/flutter/engine/blob/fce95c01cffab4fa96619d9dea6c0db121fef236/lib/web_ui/lib/src/engine/text_editing/text_editing.dart#L1648
// Android:
// https://github.com/flutter/engine/blob/fce95c01cffab4fa96619d9dea6c0db121fef236/lib/web_ui/lib/src/engine/text_editing/text_editing.dart#L1773
bool get windowHasFocus =>
    js_util.callMethod<bool>(html.window.document, 'hasFocus', <dynamic>[]);
