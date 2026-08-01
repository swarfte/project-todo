import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_step.freezed.dart';
part 'task_step.g.dart';

/// One step in a task's linear chain. Steps form a linked list via
/// `previousStepId` (each step points at its predecessor, with at most one
/// successor each).
///
/// Some collections rely on PocketBase's built-in `created` / `updated` audit
/// fields instead of custom `createdAt`/`updatedAt` fields. Because that
/// fallback needs to look at a *second* JSON field, it can't be expressed as a
/// per-field [JsonConverter]; instead the whole-record decoding lives in
/// [TaskStep.fromPocketBaseJson], which the generated [fromJson] delegates to.
@freezed
abstract class TaskStep with _$TaskStep {
  const factory TaskStep({
    required String id,
    required String name,
    required String taskId,

    @Default(false) final bool isCompleted,

    /// Creation time. Decoded (with fallback to `created`) by
    /// [fromPocketBaseJson] before the generated constructor runs, so the
    /// plain [DateTime] type here never has to parse a missing/empty string.
    required final DateTime createdAt,

    /// Last-update time. Falls back to `updated` — see [createdAt].
    required final DateTime updatedAt,

    /// Id of the step that comes immediately before this one in the chain,
    /// or null if this step is a chain head.
    final String? previousStepId,
  }) = _TaskStep;

  /// Decodes a PocketBase step record into a [TaskStep], applying the
  /// `createdAt`→`created` and `updatedAt`→`updated` fallback and the empty /
  /// null-string date handling the original hand-written adaptor did.
  ///
  /// Without this fallback `DateTime.parse(null)` would throw and the whole
  /// step list would fail to load when a collection only carries the built-in
  /// audit fields.
  factory TaskStep.fromJson(Map<String, dynamic> json) =>
      TaskStep.fromPocketBaseJson(json);

  factory TaskStep.fromPocketBaseJson(Map<String, dynamic> json) {
    DateTime parseDate(String primary, String fallback) {
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

    return TaskStep(
      id: json['id'] as String,
      name: json['name'] as String,
      taskId: json['taskId'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: parseDate('createdAt', 'created'),
      updatedAt: parseDate('updatedAt', 'updated'),
      previousStepId: json['previousStepId'] as String?,
    );
  }
}
