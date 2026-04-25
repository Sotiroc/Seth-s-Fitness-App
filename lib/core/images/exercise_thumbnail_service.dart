import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_thumbnail_service.g.dart';

class ExerciseThumbnailService {
  const ExerciseThumbnailService();

  static const int _targetSize = 512;
  static const int _jpegQuality = 82;

  Future<Uint8List?> processPickedImage(XFile file) async {
    final Uint8List original = await file.readAsBytes();
    final img.Image? decoded = img.decodeImage(original);
    if (decoded == null) return null;

    final img.Image square = _centerCropSquare(decoded);
    final img.Image resized = img.copyResize(
      square,
      width: _targetSize,
      height: _targetSize,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  img.Image _centerCropSquare(img.Image source) {
    final int side = source.width < source.height
        ? source.width
        : source.height;
    final int x = (source.width - side) ~/ 2;
    final int y = (source.height - side) ~/ 2;
    return img.copyCrop(source, x: x, y: y, width: side, height: side);
  }
}

@Riverpod(keepAlive: true)
ExerciseThumbnailService exerciseThumbnailService(Ref ref) {
  return const ExerciseThumbnailService();
}
