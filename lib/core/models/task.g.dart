// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  name: json['name'] as String,
  projectId: json['projectId'] as String,
  isCompleted: json['isCompleted'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  dueDate: _parseNullableDate(json['dueDate'] as String?),
  previousTaskId: json['previousTaskId'] as String?,
  completedAt: _parseNullableDate(json['completedAt'] as String?),
  isFolded: json['isFolded'] as bool? ?? false,
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'projectId': instance.projectId,
  'isCompleted': instance.isCompleted,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'dueDate': _formatNullableDate(instance.dueDate),
  'previousTaskId': instance.previousTaskId,
  'completedAt': _formatNullableDate(instance.completedAt),
  'isFolded': instance.isFolded,
};
