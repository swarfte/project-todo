import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_step.freezed.dart';
part 'task_step.g.dart';

/// One step in a task's linear chain. Steps form a linked list via
/// `previousStepId` (each step points at its predecessor, with at most one
/// successor each).
///
/// Some collections rely on PocketBase's built-in `created` / `updated` audit
/// fields instead of custom `createdAt`/`updatedAt` fields. The date
/// converters below fall back to those built-ins so a missing custom field
/// doesn't crash the whole step list.
@freezed
class TaskStep with _$TaskStep {
  const factory TaskStep({
    required String id,
    required String name,
    required String taskId,

    // ignore: invalid_annotation_target
    @Default(false) final bool isCompleted,

    /// Creation time, falling back to PocketBase's built-in `created` field
    /// when the custom `createdAt` is missing or empty. If both are absent a
    /// sentinel epoch is used so the UI never crashes on missing dates.
    @JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt)
    required final DateTime createdAt,

    /// Last-update time, falling back to PocketBase's built-in `updated`
    /// field under the same rules as [createdAt].
    @JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt)
    required final DateTime updatedAt,

    /// Id of the step that comes immediately before this one in the chain,
    /// or null if this step is a chain head.
    final String? previousStepId,
  }) = _TaskStep;

  factory TaskStep.fromJson(Map<String, dynamic> json) =>
      _$TaskStepFromJson(json);
}

/// Picks a non-empty value among [primary] and [fallback], falling back to a
/// sentinel epoch so a totally missing date never throws `DateTime.parse(null)`.
DateTime _parseDateWithFallback(
  Map<String, dynamic> json,
  String primary,
  String fallback,
) {
  final primaryStr = json[primary] as String?;
  if (primaryStr != null && primaryStr.isNotEmpty) {
    return DateTime.parse(primaryStr);
  }
  final fallbackStr = json[fallback] as String?;
  if (fallbackStr != null && fallbackStr.isNotEmpty) {
    return DateTime.parse(fallbackStr);
  }
  // Last resort so the UI never crashes on missing dates.
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime _parseCreatedAt(Map<String, dynamic> json) =>
    _parseDateWithFallback(json, 'createdAt', 'created');

DateTime _parseUpdatedAt(Map<String, dynamic> json) =>
    _parseDateWithFallback(json, 'updatedAt', 'updated');

// The toJson side mirrors the primary field names PocketBase stores, so the
// original value round-trips through the custom `createdAt`/`updatedAt` keys.
String _formatCreatedAt(DateTime value) => value.toIso8601String();
String _formatUpdatedAt(DateTime value) => value.toIso8601String();
