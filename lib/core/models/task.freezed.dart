// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id; String get name; String get projectId; bool get isCompleted; DateTime get createdAt; DateTime get updatedAt;/// Optional deadline. null means the task has no due date.
@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? get dueDate;/// Id of the task that comes immediately before this one in the chain,
/// or null if this task is a chain root.
 String? get previousTaskId;/// When the task was marked complete, if ever.
@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? get completedAt;/// Whether the task's descendants are currently hidden in the UI.
// ignore: invalid_annotation_target
 bool get isFolded;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.previousTaskId, previousTaskId) || other.previousTaskId == previousTaskId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isFolded, isFolded) || other.isFolded == isFolded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,projectId,isCompleted,createdAt,updatedAt,dueDate,previousTaskId,completedAt,isFolded);

@override
String toString() {
  return 'Task(id: $id, name: $name, projectId: $projectId, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt, dueDate: $dueDate, previousTaskId: $previousTaskId, completedAt: $completedAt, isFolded: $isFolded)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String name, String projectId, bool isCompleted, DateTime createdAt, DateTime updatedAt,@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? dueDate, String? previousTaskId,@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? completedAt, bool isFolded
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? projectId = null,Object? isCompleted = null,Object? createdAt = null,Object? updatedAt = null,Object? dueDate = freezed,Object? previousTaskId = freezed,Object? completedAt = freezed,Object? isFolded = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,previousTaskId: freezed == previousTaskId ? _self.previousTaskId : previousTaskId // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFolded: null == isFolded ? _self.isFolded : isFolded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String projectId,  bool isCompleted,  DateTime createdAt,  DateTime updatedAt, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? dueDate,  String? previousTaskId, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? completedAt,  bool isFolded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.name,_that.projectId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.dueDate,_that.previousTaskId,_that.completedAt,_that.isFolded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String projectId,  bool isCompleted,  DateTime createdAt,  DateTime updatedAt, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? dueDate,  String? previousTaskId, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? completedAt,  bool isFolded)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.name,_that.projectId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.dueDate,_that.previousTaskId,_that.completedAt,_that.isFolded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String projectId,  bool isCompleted,  DateTime createdAt,  DateTime updatedAt, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? dueDate,  String? previousTaskId, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate)  DateTime? completedAt,  bool isFolded)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.name,_that.projectId,_that.isCompleted,_that.createdAt,_that.updatedAt,_that.dueDate,_that.previousTaskId,_that.completedAt,_that.isFolded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task implements Task {
  const _Task({required this.id, required this.name, required this.projectId, required this.isCompleted, required this.createdAt, required this.updatedAt, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) this.dueDate, this.previousTaskId, @JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) this.completedAt, this.isFolded = false});
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String name;
@override final  String projectId;
@override final  bool isCompleted;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Optional deadline. null means the task has no due date.
@override@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) final  DateTime? dueDate;
/// Id of the task that comes immediately before this one in the chain,
/// or null if this task is a chain root.
@override final  String? previousTaskId;
/// When the task was marked complete, if ever.
@override@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) final  DateTime? completedAt;
/// Whether the task's descendants are currently hidden in the UI.
// ignore: invalid_annotation_target
@override@JsonKey() final  bool isFolded;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.previousTaskId, previousTaskId) || other.previousTaskId == previousTaskId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isFolded, isFolded) || other.isFolded == isFolded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,projectId,isCompleted,createdAt,updatedAt,dueDate,previousTaskId,completedAt,isFolded);

@override
String toString() {
  return 'Task(id: $id, name: $name, projectId: $projectId, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt, dueDate: $dueDate, previousTaskId: $previousTaskId, completedAt: $completedAt, isFolded: $isFolded)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String projectId, bool isCompleted, DateTime createdAt, DateTime updatedAt,@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? dueDate, String? previousTaskId,@JsonKey(fromJson: _parseNullableDate, toJson: _formatNullableDate) DateTime? completedAt, bool isFolded
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? projectId = null,Object? isCompleted = null,Object? createdAt = null,Object? updatedAt = null,Object? dueDate = freezed,Object? previousTaskId = freezed,Object? completedAt = freezed,Object? isFolded = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,previousTaskId: freezed == previousTaskId ? _self.previousTaskId : previousTaskId // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFolded: null == isFolded ? _self.isFolded : isFolded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
