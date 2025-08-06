// lib/services/habit_service.dart

import 'package:myme_app/models/habit.dart';
import 'package:myme_app/models/habit_log.dart';
import 'package:intl/intl.dart'; // 날짜 비교를 위해 추가

class HabitService {
  // --- Singleton Pattern ---
  // 앱 전체에서 단 하나의 인스턴스만 존재하도록 만듭니다.
  static final HabitService _instance = HabitService._internal();

  factory HabitService() {
    return _instance;
  }

  HabitService._internal();
  // -------------------------

  // 임시 데이터 저장을 위한 인메모리 리스트
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];

  // --- Habit CRUD ---

  // 모든 습관 목록 가져오기
  Future<List<Habit>> getAllHabits() async {
    // 실제 앱에서는 DB에서 데이터를 가져옵니다.
    await Future.delayed(const Duration(milliseconds: 50)); // 가짜 딜레이
    return List.from(_habits);
  }

  // 오늘 날짜에 활성화된 습관 목록 가져오기
  Future<List<Habit>> getTodaysHabits() async {
    final today = DateTime.now();
    // 시간, 분, 초를 0으로 설정하여 날짜만 비교하도록 함
    final startOfToday = DateTime(today.year, today.month, today.day);

    final todaysHabits = _habits.where((habit) {
      // 시작일이 오늘이거나 오늘보다 이전인지 확인
      final isStarted = !habit.startDate.isAfter(startOfToday);

      // 종료일이 없거나, 오늘이거나, 오늘보다 이후인지 확인
      final isNotEnded = habit.endDate == null || !startOfToday.isAfter(habit.endDate!);

      return isStarted && isNotEnded;
    }).toList();
    
    await Future.delayed(const Duration(milliseconds: 50)); // 가짜 딜레이
    return todaysHabits;
  }

  // 새로운 습관 추가
  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
  }

  // 습관 정보 업데이트
  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
    }
  }

  // 습관 삭제
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    // 관련된 로그도 모두 삭제
    _logs.removeWhere((log) => log.habitId == habitId);
  }

  // --- HabitLog CRUD ---

  // 특정 습관의 모든 로그 가져오기
  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    return _logs.where((log) => log.habitId == habitId).toList();
  }
  
  // 특정 날짜의 모든 로그 가져오기
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateString = formatter.format(date);
    return _logs.where((log) => formatter.format(log.date) == dateString).toList();
  }

  // 로그 추가 또는 업데이트
  Future<void> addOrUpdateLog(HabitLog log) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final logDateString = formatter.format(log.date);

    final index = _logs.indexWhere((l) => l.habitId == log.habitId && formatter.format(l.date) == logDateString);
    
    if (index != -1) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
  }

  // 특정 날짜의 특정 습관 로그 삭제
  Future<void> deleteLog(String habitId, DateTime date) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateString = formatter.format(date);
    _logs.removeWhere((log) => log.habitId == habitId && formatter.format(log.date) == dateString);
  }
}
