// IO implementation (Android/iOS/desktop).
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';

Future<bool> savePngBytesImpl({
  required Uint8List pngBytes,
  required String filename,
}) async {
  final name = filename.endsWith('.png')
      ? filename.substring(0, filename.length - 4)
      : filename;

  final res = await ImageGallerySaver.saveImage(
    pngBytes,
    name: name,
    quality: 100,
  );

  return (res['isSuccess'] == true) || (res['filePath'] != null);
}

