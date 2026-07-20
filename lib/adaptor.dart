import 'package:project_todo/models.dart';

class ProjectAdaptor {
  static Project fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Map<String, dynamic> toJson(Project project) {
    return {
      "id": project.id,
      "name": project.name,
      "userId": project.userId,
      "createdAt": project.createdAt.toIso8601String(),
      "updatedAt": project.updatedAt.toIso8601String(),
    };
  }
}

class TaskAdaptor {
  static Task fromJson(Map<String, dynamic> json) {
    // PocketBase serializes empty date fields as "" rather than null.
    final dueDateStr = json['dueDate'] as String?;
    final completedAtStr = json['completedAt'] as String?;
    final isFolded = json['isFolded'] as bool?;
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: dueDateStr != null && dueDateStr.isNotEmpty
          ? DateTime.parse(dueDateStr)
          : null,
      previousTaskId: json['previousTaskId'] as String?,
      completedAt: completedAtStr != null && completedAtStr.isNotEmpty
          ? DateTime.parse(completedAtStr)
          : null,
      isFolded: isFolded ?? false, // Default to false if not present
    );
  }

  static Map<String, dynamic> toJson(Task task) {
    return {
      "id": task.id,
      "name": task.name,
      "projectId": task.projectId,
      "isCompleted": task.isCompleted,
      "createdAt": task.createdAt.toIso8601String(),
      "updatedAt": task.updatedAt.toIso8601String(),
      "dueDate": task.dueDate?.toIso8601String(),
      "previousTaskId": task.previousTaskId,
      "completedAt": task.completedAt?.toIso8601String(),
      "isFolded": task.isFolded,
    };
  }
}

class StepAdaptor {
  static TaskStep fromJson(Map<String, dynamic> json) {
    // PocketBase serializes empty date fields as "" rather than null.
    // Also, some collections rely on PocketBase's built-in `created` /
    // `updated` audit fields instead of custom `createdAt`/`updatedAt`
    // fields, so fall back to those if the custom fields are absent.
    // Without this fallback, `DateTime.parse(null)` throws and the whole
    // step list fails to load.
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

  static Map<String, dynamic> toJson(TaskStep step) {
    return {
      "id": step.id,
      "name": step.name,
      "taskId": step.taskId,
      "isCompleted": step.isCompleted,
      "createdAt": step.createdAt.toIso8601String(),
      "updatedAt": step.updatedAt.toIso8601String(),
      "previousStepId": step.previousStepId,
    };
  }
}
