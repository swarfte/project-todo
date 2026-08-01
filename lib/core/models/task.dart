import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// A task belonging to a [Project]. Tasks form a forest via `previousTaskId`
/// (each task points at its predecessor, which may have many successors).
///
/// PocketBase serializes empty date fields as `""` rather than `null`, so the
/// optional dates go through [_parseNullableDate] which treats `""` and `null`
/// the same way (no value).
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String name,
    required String projectId,
    required bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Optional deadline. null means the task has no due date.
    @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)
    final DateTime? dueDate,

    /// Id of the task that comes immediately before this one in the chain,
    /// or null if this task is a chain root.
    final String? previousTaskId,

    /// When the task was marked complete, if ever.
    @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)
    final DateTime? completedAt,

    /// Whether the task's descendants are currently hidden in the UI.
    // ignore: invalid_annotation_target
    @Default(false) final bool isFolded,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

/// Parses an optional date string that PocketBase may emit as `""` (empty)
/// instead of `null`. Both empty and null become a null [DateTime].
DateTime? _parseNullableDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.parse(value);
}

/// Inverse of [_parseNullableDate]: emits an ISO string, or null when there is
/// no value. json_serializable omits null-valued nullable fields by default,
/// matching the original adaptor's behaviour for absent dates.
String? _formatNullableDate(DateTime? value) => value?.toIso8601String();
