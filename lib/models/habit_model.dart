
import 'package:myme_app/models/tag_model.dart';

enum HabitTrackingType {
  checkOnly,
  time,
  percentage,
  quantity,
}

class Habit {
  String id;
  String title;
  String content;
  String emoji;
  DateTime startDate;
  DateTime? endDate;
  HabitTrackingType trackingType;
  String? goalUnit;
  bool showLogEditorOnCheck;
  List<Tag> tags;
  int ownerId;
  int createdBy;
  int updatedBy;
  DateTime createdAt;
  DateTime updatedAt;

  Habit({
    required this.id,
    required this.title,
    this.content = '',
    this.emoji = '😊',
    required this.startDate,
    this.endDate,
    this.trackingType = HabitTrackingType.checkOnly,
    this.goalUnit,
    this.showLogEditorOnCheck = false,
    this.tags = const [],
    required this.ownerId,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'emoji': emoji,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'tracking_type': trackingType.toString(),
      'goal_unit': goalUnit,
      'show_log_editor_on_check': showLogEditorOnCheck ? 1 : 0,
      'owner_id': ownerId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      emoji: map['emoji'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      trackingType: HabitTrackingType.values.firstWhere(
        (e) => e.toString() == map['tracking_type'],
        orElse: () => HabitTrackingType.checkOnly,
      ),
      goalUnit: map['goal_unit'],
      showLogEditorOnCheck: map['show_log_editor_on_check'] == 1,
      ownerId: map['owner_id'],
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
