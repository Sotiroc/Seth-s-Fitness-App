import 'dart:typed_data';

import 'image_share_io.dart'
    if (dart.library.js_interop) 'image_share_web.dart' as platform;

/// Hands a captured PNG off to the system share sheet (mobile/desktop)
/// or triggers a download (web). Implementation is platform-split via
/// conditional import so the runtime tree only pulls the relevant code.
///
/// Returns `true` if the share/download was kicked off, `false` if the
/// platform doesn't have a meaningful target. Errors are surfaced to
/// the caller so the UI can show a snackbar.
Future<bool> shareImagePng({
  required Uint8List bytes,
  required String filename,
  String? title,
}) {
  return platform.sharePngBytes(
    bytes: bytes,
    filename: filename,
    title: title,
  );
}
