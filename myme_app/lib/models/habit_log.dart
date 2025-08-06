// lib/models/habit_log.dart

class HabitLog {
  String id;
  String habitId;
  DateTime date;
  String? memo;
  bool isCompleted;
  int? timeValue;
  int? percentageValue;
  int? quantityValue;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.memo,
    this.isCompleted = true,
    this.timeValue,
    this.percentageValue,
    this.quantityValue,
  });
}
