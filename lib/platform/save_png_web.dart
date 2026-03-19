// Web-only implementation.
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> savePngBytesImpl({
  required Uint8List pngBytes,
  required String filename,
}) async {
  final blob = html.Blob(<Object>[pngBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final a = html.AnchorElement(href: url)
      ..download = filename.endsWith('.png') ? filename : '$filename.png'
      ..style.display = 'none';
    html.document.body?.children.add(a);
    a.click();
    a.remove();
    return true;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}

