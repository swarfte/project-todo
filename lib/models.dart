class Project {
  String id;
  String name;
  String userId;
  DateTime createdAt;
  DateTime updatedAt;
  List<Task>? tasks;
  bool isCompleted;

  Project({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.tasks,
    required this.isCompleted,
  });
}

class Task {
  String id;
  String name;
  String projectId;
  String userId;
  bool isCompleted;
  DateTime? dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  Task? previousTask;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.userId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.dueDate,
    required this.previousTask,
  });
}
