// lib/models/habit_log.dart

class HabitLog {
  String id;
  String habitId;
  DateTime date; // logDate
  String? memo;
  bool isCompleted;
  int? timeValue;
  int? percentageValue;
  int? quantityValue;
  DateTime? createdAt;
  DateTime? updatedAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.memo,
    this.isCompleted = true,
    this.timeValue,
    this.percentageValue,
    this.quantityValue,
    this.createdAt,
    this.updatedAt,
  });

  HabitLog copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    String? memo,
    bool? isCompleted,
    int? timeValue,
    int? percentageValue,
    int? quantityValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      isCompleted: isCompleted ?? this.isCompleted,
      timeValue: timeValue ?? this.timeValue,
      percentageValue: percentageValue ?? this.percentageValue,
      quantityValue: quantityValue ?? this.quantityValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}