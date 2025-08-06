// lib/models/habit.dart

enum HabitTrackingType {
  checkOnly,
  time,
  percentage,
  quantity
}

class Habit {
  String id;
  String title;
  String content;
  String emoji;
  DateTime startDate;
  DateTime? endDate;
  HabitTrackingType trackingType; // '대표' 통계 유형
  bool showLogEditorOnCheck; // 체크 시 로그 편집창 표시 여부

  Habit({
    required this.id,
    required this.title,
    required this.content,
    required this.emoji,
    required this.startDate,
    this.endDate,
    required this.trackingType,
    this.showLogEditorOnCheck = false, // 기본값은 false (즉시 저장)
  });
}