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
      "userId": project.userId,
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
      previousTaskId: json['previousTaskId'] as String?,
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
      "previousTaskId": task.previousTaskId,
      "completedAt": task.completedAt?.toIso8601String(),
    };
  }
}

class StepAdaptor {
  static Step fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'] as String,
      name: json['name'] as String,
      taskId: json['taskId'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      previousStepId: json['previousStepId'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Step step) {
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
