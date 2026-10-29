// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cognitive_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CognitiveTaskImpl _$$CognitiveTaskImplFromJson(Map<String, dynamic> json) =>
    _$CognitiveTaskImpl(
      id: json['id'] as String,
      section: json['section'] as String,
      task: json['task'] as String,
      goal: json['goal'] as String,
      daysOfWeek: Map<String, bool>.from(json['daysOfWeek'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isCompletedToday: json['isCompletedToday'] as bool? ?? false,
    );

Map<String, dynamic> _$$CognitiveTaskImplToJson(_$CognitiveTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'section': instance.section,
      'task': instance.task,
      'goal': instance.goal,
      'daysOfWeek': instance.daysOfWeek,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'isCompletedToday': instance.isCompletedToday,
    };
