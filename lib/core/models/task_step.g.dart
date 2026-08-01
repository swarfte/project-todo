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
  createdAt: _parseCreatedAt(json['createdAt'] as Map<String, dynamic>),
  updatedAt: _parseUpdatedAt(json['updatedAt'] as Map<String, dynamic>),
  previousStepId: json['previousStepId'] as String?,
);

Map<String, dynamic> _$TaskStepToJson(_TaskStep instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'taskId': instance.taskId,
  'isCompleted': instance.isCompleted,
  'createdAt': _formatCreatedAt(instance.createdAt),
  'updatedAt': _formatUpdatedAt(instance.updatedAt),
  'previousStepId': instance.previousStepId,
};
