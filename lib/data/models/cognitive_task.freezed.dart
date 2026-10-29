// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cognitive_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CognitiveTask _$CognitiveTaskFromJson(Map<String, dynamic> json) {
  return _CognitiveTask.fromJson(json);
}

/// @nodoc
mixin _$CognitiveTask {
  String get id => throw _privateConstructorUsedError;
  String get section => throw _privateConstructorUsedError;
  String get task => throw _privateConstructorUsedError;
  String get goal => throw _privateConstructorUsedError;
  Map<String, bool> get daysOfWeek =>
      throw _privateConstructorUsedError; // Mon, Tue, Wed, etc.
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  bool get isCompletedToday => throw _privateConstructorUsedError;

  /// Serializes this CognitiveTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CognitiveTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CognitiveTaskCopyWith<CognitiveTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CognitiveTaskCopyWith<$Res> {
  factory $CognitiveTaskCopyWith(
    CognitiveTask value,
    $Res Function(CognitiveTask) then,
  ) = _$CognitiveTaskCopyWithImpl<$Res, CognitiveTask>;
  @useResult
  $Res call({
    String id,
    String section,
    String task,
    String goal,
    Map<String, bool> daysOfWeek,
    DateTime createdAt,
    DateTime? completedAt,
    bool isCompletedToday,
  });
}

/// @nodoc
class _$CognitiveTaskCopyWithImpl<$Res, $Val extends CognitiveTask>
    implements $CognitiveTaskCopyWith<$Res> {
  _$CognitiveTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CognitiveTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? section = null,
    Object? task = null,
    Object? goal = null,
    Object? daysOfWeek = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? isCompletedToday = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            section: null == section
                ? _value.section
                : section // ignore: cast_nullable_to_non_nullable
                      as String,
            task: null == task
                ? _value.task
                : task // ignore: cast_nullable_to_non_nullable
                      as String,
            goal: null == goal
                ? _value.goal
                : goal // ignore: cast_nullable_to_non_nullable
                      as String,
            daysOfWeek: null == daysOfWeek
                ? _value.daysOfWeek
                : daysOfWeek // ignore: cast_nullable_to_non_nullable
                      as Map<String, bool>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isCompletedToday: null == isCompletedToday
                ? _value.isCompletedToday
                : isCompletedToday // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CognitiveTaskImplCopyWith<$Res>
    implements $CognitiveTaskCopyWith<$Res> {
  factory _$$CognitiveTaskImplCopyWith(
    _$CognitiveTaskImpl value,
    $Res Function(_$CognitiveTaskImpl) then,
  ) = __$$CognitiveTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String section,
    String task,
    String goal,
    Map<String, bool> daysOfWeek,
    DateTime createdAt,
    DateTime? completedAt,
    bool isCompletedToday,
  });
}

/// @nodoc
class __$$CognitiveTaskImplCopyWithImpl<$Res>
    extends _$CognitiveTaskCopyWithImpl<$Res, _$CognitiveTaskImpl>
    implements _$$CognitiveTaskImplCopyWith<$Res> {
  __$$CognitiveTaskImplCopyWithImpl(
    _$CognitiveTaskImpl _value,
    $Res Function(_$CognitiveTaskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CognitiveTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? section = null,
    Object? task = null,
    Object? goal = null,
    Object? daysOfWeek = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? isCompletedToday = null,
  }) {
    return _then(
      _$CognitiveTaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        section: null == section
            ? _value.section
            : section // ignore: cast_nullable_to_non_nullable
                  as String,
        task: null == task
            ? _value.task
            : task // ignore: cast_nullable_to_non_nullable
                  as String,
        goal: null == goal
            ? _value.goal
            : goal // ignore: cast_nullable_to_non_nullable
                  as String,
        daysOfWeek: null == daysOfWeek
            ? _value._daysOfWeek
            : daysOfWeek // ignore: cast_nullable_to_non_nullable
                  as Map<String, bool>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isCompletedToday: null == isCompletedToday
            ? _value.isCompletedToday
            : isCompletedToday // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CognitiveTaskImpl implements _CognitiveTask {
  const _$CognitiveTaskImpl({
    required this.id,
    required this.section,
    required this.task,
    required this.goal,
    required final Map<String, bool> daysOfWeek,
    required this.createdAt,
    this.completedAt,
    this.isCompletedToday = false,
  }) : _daysOfWeek = daysOfWeek;

  factory _$CognitiveTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$CognitiveTaskImplFromJson(json);

  @override
  final String id;
  @override
  final String section;
  @override
  final String task;
  @override
  final String goal;
  final Map<String, bool> _daysOfWeek;
  @override
  Map<String, bool> get daysOfWeek {
    if (_daysOfWeek is EqualUnmodifiableMapView) return _daysOfWeek;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_daysOfWeek);
  }

  // Mon, Tue, Wed, etc.
  @override
  final DateTime createdAt;
  @override
  final DateTime? completedAt;
  @override
  @JsonKey()
  final bool isCompletedToday;

  @override
  String toString() {
    return 'CognitiveTask(id: $id, section: $section, task: $task, goal: $goal, daysOfWeek: $daysOfWeek, createdAt: $createdAt, completedAt: $completedAt, isCompletedToday: $isCompletedToday)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CognitiveTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.task, task) || other.task == task) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            const DeepCollectionEquality().equals(
              other._daysOfWeek,
              _daysOfWeek,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isCompletedToday, isCompletedToday) ||
                other.isCompletedToday == isCompletedToday));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    section,
    task,
    goal,
    const DeepCollectionEquality().hash(_daysOfWeek),
    createdAt,
    completedAt,
    isCompletedToday,
  );

  /// Create a copy of CognitiveTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CognitiveTaskImplCopyWith<_$CognitiveTaskImpl> get copyWith =>
      __$$CognitiveTaskImplCopyWithImpl<_$CognitiveTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CognitiveTaskImplToJson(this);
  }
}

abstract class _CognitiveTask implements CognitiveTask {
  const factory _CognitiveTask({
    required final String id,
    required final String section,
    required final String task,
    required final String goal,
    required final Map<String, bool> daysOfWeek,
    required final DateTime createdAt,
    final DateTime? completedAt,
    final bool isCompletedToday,
  }) = _$CognitiveTaskImpl;

  factory _CognitiveTask.fromJson(Map<String, dynamic> json) =
      _$CognitiveTaskImpl.fromJson;

  @override
  String get id;
  @override
  String get section;
  @override
  String get task;
  @override
  String get goal;
  @override
  Map<String, bool> get daysOfWeek; // Mon, Tue, Wed, etc.
  @override
  DateTime get createdAt;
  @override
  DateTime? get completedAt;
  @override
  bool get isCompletedToday;

  /// Create a copy of CognitiveTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CognitiveTaskImplCopyWith<_$CognitiveTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
