// lib/screens/todays_habits_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/models/habit_log.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:myme_app/screens/add_habit_screen.dart';
import 'package:uuid/uuid.dart';

class TodaysHabitsScreen extends StatefulWidget {
  const TodaysHabitsScreen({super.key});

  @override
  State<TodaysHabitsScreen> createState() => _TodaysHabitsScreenState();
}

class _TodaysHabitsScreenState extends State<TodaysHabitsScreen> {
  final HabitService _habitService = HabitService();
  
  List<Habit> _todaysHabits = [];
  Map<String, HabitLog> _todaysLogs = {}; // <habitId, HabitLog>
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitService.getTodaysHabits();
      final logs = await _habitService.getLogsForDate(DateTime.now());
      setState(() {
        _todaysHabits = habits;
        _todaysLogs = {for (var log in logs) log.habitId: log};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _navigateToAddHabitScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHabitScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _onCheckboxChanged(bool? value, Habit habit) {
    // 체크가 해제되면 로그를 삭제하고 UI를 새로고침합니다.
    if (value == false) {
      _habitService.deleteLog(habit.id, DateTime.now()).then((_) => _loadData());
      return;
    }

    // 체크가 되면, 설정에 따라 동작을 분기합니다.
    if (habit.showLogEditorOnCheck) {
      // 편집창을 열도록 설정된 경우
      _showLogEditorDialog(habit, _todaysLogs[habit.id]);
    } else {
      // 즉시 저장하도록 설정된 경우
      final newLog = HabitLog(
        id: const Uuid().v4(),
        habitId: habit.id,
        date: DateTime.now(),
        isCompleted: true,
      );
      _habitService.addOrUpdateLog(newLog).then((_) => _loadData());
    }
  }

  Future<void> _showLogEditorDialog(Habit habit, HabitLog? existingLog) async {
    final isNewLog = existingLog == null;
    final logToEdit = existingLog ?? HabitLog(id: const Uuid().v4(), habitId: habit.id, date: DateTime.now());

    final timeController = TextEditingController(text: logToEdit.timeValue?.toString() ?? '');
    final percentController = TextEditingController(text: logToEdit.percentageValue?.toString() ?? '');
    final quantityController = TextEditingController(text: logToEdit.quantityValue?.toString() ?? '');
    final memoController = TextEditingController(text: logToEdit.memo ?? '');
    bool isCompleted = logToEdit.isCompleted;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // 팝업 내의 상태 관리를 위해 사용
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Log: ${habit.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Mark as Completed'),
                      value: isCompleted,
                      onChanged: (value) => setDialogState(() => isCompleted = value),
                    ),
                    TextFormField(
                      controller: timeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Time (minutes)'),
                    ),
                    TextFormField(
                      controller: percentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Percentage (%)'),
                    ),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity / Count'),
                    ),
                    TextFormField(
                      controller: memoController,
                      decoration: const InputDecoration(labelText: 'Memo (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final updatedLog = HabitLog(
                      id: logToEdit.id,
                      habitId: habit.id,
                      date: logToEdit.date,
                      isCompleted: isCompleted,
                      timeValue: int.tryParse(timeController.text),
                      percentageValue: int.tryParse(percentController.text),
                      quantityValue: int.tryParse(quantityController.text),
                      memo: memoController.text,
                    );
                    _habitService.addOrUpdateLog(updatedLog).then((_) {
                      Navigator.pop(context);
                      _loadData();
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Habits"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () { /* TODO: 전체 습관 목록 화면으로 이동 */ },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todaysHabits.isEmpty
              ? _buildEmptyView()
              : _buildHabitList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabitScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitList() {
    return ListView.builder(
      itemCount: _todaysHabits.length,
      itemBuilder: (context, index) {
        final habit = _todaysHabits[index];
        final log = _todaysLogs[habit.id];
        final isCompleted = log != null && log.isCompleted;

        return ListTile(
          leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(habit.title),
          subtitle: log != null ? Text(_getLogSummary(log)) : null,
          trailing: Checkbox(
            value: isCompleted,
            onChanged: (bool? value) => _onCheckboxChanged(value, habit),
          ),
          onTap: () {
            // 리스트 타일을 탭해도 편집창을 열 수 있도록 함
            if (log != null) {
              _showLogEditorDialog(habit, log);
            }
          },
        );
      },
    );
  }

  String _getLogSummary(HabitLog log) {
    if (!log.isCompleted && (log.memo == null || log.memo!.isEmpty)) {
      return 'Not completed';
    }
    List<String> parts = [];
    if (log.timeValue != null) parts.add('Time: ${log.timeValue}m');
    if (log.percentageValue != null) parts.add('${log.percentageValue}%');
    if (log.quantityValue != null) parts.add('Count: ${log.quantityValue}');
    if (log.memo != null && log.memo!.isNotEmpty) parts.add(log.memo!);
    
    if (parts.isEmpty) {
        return log.isCompleted ? 'Completed' : 'Not completed';
    }
    return parts.join(' / ');
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No habits for today.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Tap '+' to add a new one!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}