// Determine if the current browser window has focus or not on the web.
// On mobile it will always return true.
export 'window_focus_mobile.dart'
    if (dart.library.html) 'window_focus_web.dart';
