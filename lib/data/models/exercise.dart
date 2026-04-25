import 'dart:typed_data';

import 'exercise_muscle_group.dart';
import 'exercise_type.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroup,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.thumbnailBytes,
  });

  final String id;
  final String name;
  final ExerciseType type;
  final ExerciseMuscleGroup muscleGroup;
  final String? thumbnailPath;
  final Uint8List? thumbnailBytes;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    ExerciseMuscleGroup? muscleGroup,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearThumbnailPath = false,
    bool clearThumbnailBytes = false,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      thumbnailPath: clearThumbnailPath
          ? null
          : thumbnailPath ?? this.thumbnailPath,
      thumbnailBytes: clearThumbnailBytes
          ? null
          : thumbnailBytes ?? this.thumbnailBytes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
