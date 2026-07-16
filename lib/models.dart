class Project {
  String id;
  String name;
  String userId;
  DateTime createdAt;
  DateTime updatedAt;
  bool isCompleted;
  DateTime? completedAt;

  Project({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.isCompleted,
    this.completedAt,
  });
}

class Task {
  String id;
  String name;
  String projectId;
  bool isCompleted;
  DateTime? dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  String? previousTaskId;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.previousTaskId,
    this.completedAt,
  });
}

class Step {
  String id;
  String name;
  String taskId;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;
  String? previousStepId;

  Step({
    required this.id,
    required this.name,
    required this.taskId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.previousStepId,
  });
}
