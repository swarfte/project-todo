class Project {
  String id;
  String name;
  String userId;
  DateTime createdAt;
  DateTime updatedAt;
  List<Task>? tasks;
  bool isCompleted;
  DateTime? completedAt;

  Project({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.tasks,
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
  Task? previousTask;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.previousTask,
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
  Step previousStep;

  Step({
    required this.id,
    required this.name,
    required this.taskId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.previousStep,
  });
}
