import 'package:project_todo/models.dart';

class ProjectAdaptor {
  static Project fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toJson(Project project) {
    return {
      "id": project.id,
      "name": project.name,
      "user": project.userId,
      "createdAt": project.createdAt.toIso8601String(),
      "updatedAt": project.updatedAt.toIso8601String(),
      "isCompleted": project.isCompleted,
      "completedAt": project.completedAt?.toIso8601String(),
    };
  }
}

class TaskAdaptor {
  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      previousTask: json['previousTask'] != null
          ? TaskAdaptor.fromJson(json['previousTask'] as Map<String, dynamic>)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
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
      "previousTask": task.previousTask != null
          ? TaskAdaptor.toJson(task.previousTask!)
          : null,
      "completedAt": task.completedAt?.toIso8601String(),
    };
  }
}
