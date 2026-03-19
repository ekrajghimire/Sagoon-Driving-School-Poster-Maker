import 'dart:typed_data';

import 'save_png_stub.dart'
    if (dart.library.html) 'save_png_web.dart'
    if (dart.library.io) 'save_png_io.dart';

/// Saves PNG bytes to the best available target for the platform.
///
/// - Web: downloads a `.png` file
/// - IO (Android/iOS/desktop): saves to gallery (implementation uses plugins)
Future<bool> savePngBytes({
  required Uint8List pngBytes,
  required String filename,
}) =>
    savePngBytesImpl(pngBytes: pngBytes, filename: filename);

