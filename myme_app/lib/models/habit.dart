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
  String? goalUnit; // 대표 단위
  bool showLogEditorOnCheck; // 체크 시 로그 편집창 표시 여부
  List<String> tagIds; // 태그 ID 목록

  Habit({
    required this.id,
    required this.title,
    required this.content,
    required this.emoji,
    required this.startDate,
    this.endDate,
    required this.trackingType,
    this.goalUnit,
    this.showLogEditorOnCheck = false, // 기본값은 false (즉시 저장)
    this.tagIds = const [], // 기본값은 빈 리스트
  });

  Habit copyWith({
    String? id,
    String? title,
    String? content,
    String? emoji,
    DateTime? startDate,
    DateTime? endDate,
    HabitTrackingType? trackingType,
    String? goalUnit,
    bool? showLogEditorOnCheck,
    List<String>? tagIds,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      emoji: emoji ?? this.emoji,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trackingType: trackingType ?? this.trackingType,
      goalUnit: goalUnit ?? this.goalUnit,
      showLogEditorOnCheck: showLogEditorOnCheck ?? this.showLogEditorOnCheck,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}
