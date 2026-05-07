import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [bytes] as a PNG named [filename]. The
/// Web Share API is intentionally not used — file sharing on desktop
/// browsers is patchy, and "save the PNG and post it from the camera
/// roll" matches what the spec calls for ("designed to look good as an
/// Instagram story / iMessage attachment").
Future<bool> sharePngBytes({
  required Uint8List bytes,
  required String filename,
  String? title,
}) async {
  final web.Blob blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = filename
        ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Free the blob URL once the click has flushed; Chrome already keeps
  // the reference alive for the in-progress download.
  web.URL.revokeObjectURL(url);
  return true;
}
