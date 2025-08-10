
class HabitLog {
  String id;
  String habitId;
  DateTime date;
  String? memo;
  bool isCompleted;
  int? timeValue;
  int? percentageValue;
  int? quantityValue;
  int ownerId;
  int createdBy;
  int updatedBy;
  DateTime createdAt;
  DateTime updatedAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.memo,
    this.isCompleted = true,
    this.timeValue,
    this.percentageValue,
    this.quantityValue,
    required this.ownerId,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'memo': memo,
      'is_completed': isCompleted ? 1 : 0,
      'time_value': timeValue,
      'percentage_value': percentageValue,
      'quantity_value': quantityValue,
      'owner_id': ownerId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'],
      habitId: map['habit_id'],
      date: DateTime.parse(map['date']),
      memo: map['memo'],
      isCompleted: map['is_completed'] == 1,
      timeValue: map['time_value'],
      percentageValue: map['percentage_value'],
      quantityValue: map['quantity_value'],
      ownerId: map['owner_id'],
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
