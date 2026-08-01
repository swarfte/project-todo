import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A top-level project that owns a tree of [Task]s.
///
/// The projects collection no longer carries a stored completion flag — a
/// project is "completed" iff all of its tasks are done, which the UI derives
/// from task counts. `updatedAt` is kept fresh by PocketBase's autodate on
/// every write (and by an explicit bump when a task is created under it).
@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String userId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
