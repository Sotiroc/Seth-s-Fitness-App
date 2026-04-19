import 'exercise_type.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  final String id;
  final String name;
  final ExerciseType type;
  final String? thumbnailPath;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    String? thumbnailPath,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearThumbnailPath = false,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      thumbnailPath: clearThumbnailPath
          ? null
          : thumbnailPath ?? this.thumbnailPath,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
