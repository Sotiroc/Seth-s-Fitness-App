import 'dart:typed_data';

/// Native-platform fallback for [sharePngBytes]. The current build target
/// is web only — this stub keeps `dart:io`-tainted dependencies out of
/// the runtime and lets feature work compile on mobile shells later.
Future<bool> sharePngBytes({
  required Uint8List bytes,
  required String filename,
  String? title,
}) async {
  return false;
}
