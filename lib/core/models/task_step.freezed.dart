// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskStep {

 String get id; String get name; String get taskId; bool get isCompleted;/// Creation time, falling back to PocketBase's built-in `created` field
/// when the custom `createdAt` is missing or empty. If both are absent a
/// sentinel epoch is used so the UI never crashes on missing dates.
@JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt) DateTime get createdAt;/// Last-update time, falling back to PocketBase's built-in `updated`
/// field under the same rules as [createdAt].
@JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt) DateTime get updatedAt;/// Id of the step that comes immediately before this one in the chain,
/// or null if this step is a chain head.
 String? get previousStepId;
/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStepCopyWith<TaskStep> get copyWith => _$TaskStepCopyWithImpl<TaskStep>(this as TaskStep, _$identity);

  /// Serializes this TaskStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.previousStepId, previousStepId) || other.previousStepId == previousStepId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,taskId,isCompleted,createdAt,updatedAt,previousStepId);

@override
String toString() {
  return 'TaskStep(id: $id, name: $name, taskId: $taskId, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt, previousStepId: $previousStepId)';
}


}

/// @nodoc
abstract mixin class $TaskStepCopyWith<$Res>  {
  factory $TaskStepCopyWith(TaskStep value, $Res Function(TaskStep) _then) = _$TaskStepCopyWithImpl;
@useResult
$Res call({
 String id, String name, String taskId, bool isCompleted,@JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt) DateTime createdAt,@JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt) DateTime updatedAt, String? previousStepId
});




}
/// @nodoc
class _$TaskStepCopyWithImpl<$Res>
    implements $TaskStepCopyWith<$Res> {
  _$TaskStepCopyWithImpl(this._self, this._then);

  final TaskStep _self;
  final $Res Function(TaskStep) _then;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? taskId = null,Object? isCompleted = null,Object? createdAt = null,Object? updatedAt = null,Object? previousStepId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousStepId: freezed == previousStepId ? _self.previousStepId : previousStepId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskStep].
extension TaskStepPatterns on TaskStep {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskStep value)  $default,){
final _that = this;
switch (_that) {
case _TaskStep():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskStep value)?  $default,){
final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String taskId,  bool isCompleted, @JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt)  DateTime createdAt, @JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt)  DateTime updatedAt,  String? previousStepId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that.id,_that.name,_that.taskId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.previousStepId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String taskId,  bool isCompleted, @JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt)  DateTime createdAt, @JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt)  DateTime updatedAt,  String? previousStepId)  $default,) {final _that = this;
switch (_that) {
case _TaskStep():
return $default(_that.id,_that.name,_that.taskId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.previousStepId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String taskId,  bool isCompleted, @JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt)  DateTime createdAt, @JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt)  DateTime updatedAt,  String? previousStepId)?  $default,) {final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that.id,_that.name,_that.taskId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.previousStepId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskStep implements TaskStep {
  const _TaskStep({required this.id, required this.name, required this.taskId, this.isCompleted = false, @JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt) required this.createdAt, @JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt) required this.updatedAt, this.previousStepId});
  factory _TaskStep.fromJson(Map<String, dynamic> json) => _$TaskStepFromJson(json);

@override final  String id;
@override final  String name;
@override final  String taskId;
@override@JsonKey() final  bool isCompleted;
/// Creation time, falling back to PocketBase's built-in `created` field
/// when the custom `createdAt` is missing or empty. If both are absent a
/// sentinel epoch is used so the UI never crashes on missing dates.
@override@JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt) final  DateTime createdAt;
/// Last-update time, falling back to PocketBase's built-in `updated`
/// field under the same rules as [createdAt].
@override@JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt) final  DateTime updatedAt;
/// Id of the step that comes immediately before this one in the chain,
/// or null if this step is a chain head.
@override final  String? previousStepId;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskStepCopyWith<_TaskStep> get copyWith => __$TaskStepCopyWithImpl<_TaskStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskStep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.previousStepId, previousStepId) || other.previousStepId == previousStepId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,taskId,isCompleted,createdAt,updatedAt,previousStepId);

@override
String toString() {
  return 'TaskStep(id: $id, name: $name, taskId: $taskId, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt, previousStepId: $previousStepId)';
}


}

/// @nodoc
abstract mixin class _$TaskStepCopyWith<$Res> implements $TaskStepCopyWith<$Res> {
  factory _$TaskStepCopyWith(_TaskStep value, $Res Function(_TaskStep) _then) = __$TaskStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String taskId, bool isCompleted,@JsonKey(fromJson: _parseCreatedAt, toJson: _formatCreatedAt) DateTime createdAt,@JsonKey(fromJson: _parseUpdatedAt, toJson: _formatUpdatedAt) DateTime updatedAt, String? previousStepId
});




}
/// @nodoc
class __$TaskStepCopyWithImpl<$Res>
    implements _$TaskStepCopyWith<$Res> {
  __$TaskStepCopyWithImpl(this._self, this._then);

  final _TaskStep _self;
  final $Res Function(_TaskStep) _then;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? taskId = null,Object? isCompleted = null,Object? createdAt = null,Object? updatedAt = null,Object? previousStepId = freezed,}) {
  return _then(_TaskStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousStepId: freezed == previousStepId ? _self.previousStepId : previousStepId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
