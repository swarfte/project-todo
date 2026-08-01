// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskStep _$TaskStepFromJson(Map<String, dynamic> json) => _TaskStep(
  id: json['id'] as String,
  name: json['name'] as String,
  taskId: json['taskId'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  previousStepId: json['previousStepId'] as String?,
);

Map<String, dynamic> _$TaskStepToJson(_TaskStep instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'taskId': instance.taskId,
  'isCompleted': instance.isCompleted,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'previousStepId': instance.previousStepId,
};
