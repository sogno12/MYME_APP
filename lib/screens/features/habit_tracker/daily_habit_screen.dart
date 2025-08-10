import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/habit_model.dart';
import 'package:myme_app/models/habit_log_model.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_form_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_list_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/tag_management_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_detail_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_log_form_screen.dart';

class DailyHabitScreen extends StatefulWidget {
  final int userId;
  const DailyHabitScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DailyHabitScreenState createState() => _DailyHabitScreenState();
}

class _DailyHabitScreenState extends State<DailyHabitScreen> {
  DateTime _selectedDate = DateTime.now();
  final dbHelper = DatabaseHelper.instance;
  List<Habit> _habits = [];
  Map<String, HabitLog?> _habitLogs = {}; // habitId -> HabitLog for _selectedDate

  @override
  void initState() {
    super.initState();
    _loadHabitsForSelectedDate();
  }

  Future<void> _loadHabitsForSelectedDate() async {
    final allHabits = await dbHelper.getAllHabits(widget.userId);
    final List<Habit> activeHabits = [];
    final Map<String, HabitLog?> currentHabitLogs = {};

    for (var habit in allHabits) {
      // Check if habit is active on _selectedDate
      // Normalize dates to start of day for accurate comparison
      final normalizedSelectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final normalizedHabitStartDate = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
      final normalizedHabitEndDate = habit.endDate != null
          ? DateTime(habit.endDate!.year, habit.endDate!.month, habit.endDate!.day)
          : null;

      final bool isAfterOrSameStartDate = normalizedSelectedDate.isAtSameMomentAs(normalizedHabitStartDate) ||
                                          normalizedSelectedDate.isAfter(normalizedHabitStartDate);

      final bool isBeforeOrSameEndDate = normalizedHabitEndDate == null ||
                                         normalizedSelectedDate.isAtSameMomentAs(normalizedHabitEndDate) ||
                                         normalizedSelectedDate.isBefore(normalizedHabitEndDate);

      final bool isActive = isAfterOrSameStartDate && isBeforeOrSameEndDate;

      if (isActive) {
        activeHabits.add(habit);
        final log = await dbHelper.getHabitLogForDate(habit.id, _selectedDate);
        currentHabitLogs[habit.id] = log;
      }
    }

    setState(() {
      _habits = activeHabits;
      _habitLogs = currentHabitLogs;
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadHabitsForSelectedDate();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadHabitsForSelectedDate();
    }
  }

  Future<void> _toggleHabitCompletion(Habit habit) async {
    HabitLog? logToEdit; // This will hold the log to potentially pass to the editor

    HabitLog? existingLog = _habitLogs[habit.id];

    if (existingLog != null) {
      // Update existing log
      existingLog.isCompleted = !existingLog.isCompleted;
      existingLog.updatedAt = DateTime.now();
      await dbHelper.updateHabitLog(existingLog);
      logToEdit = existingLog;
    } else {
      // Create new log
      final newLog = HabitLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
        habitId: habit.id,
        date: _selectedDate,
        isCompleted: true, // Default to completed when first checked
        ownerId: widget.userId,
        createdBy: widget.userId,
        updatedBy: widget.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbHelper.insertHabitLog(newLog);
      logToEdit = newLog;
    }

    // After updating/creating the log, check if the editor should be shown
    if (habit.showLogEditorOnCheck && logToEdit != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HabitLogFormScreen(
            userId: widget.userId,
            habitId: habit.id,
            log: logToEdit, // Pass the log that was just created/updated
          ),
        ),
      );
    }

    _loadHabitsForSelectedDate(); // Reload to reflect changes (and any changes from editor)
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '표시할 습관이 없습니다.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '새로운 습관을 추가해보세요!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitListView() {
    return ListView.builder(
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final log = _habitLogs[habit.id];
        final isCompleted = log?.isCompleted ?? false;

        return ListTile(
          leading: IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : null,
            ),
            onPressed: () => _toggleHabitCompletion(habit),
          ),
          title: Text(habit.title),
          subtitle: Text(habit.content),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to HabitLogFormScreen for editing log or adding details
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitLogFormScreen(
                    userId: widget.userId,
                    habitId: habit.id,
                    log: log, // Pass the existing log if it exists
                  ),
                ),
              );
              _loadHabitsForSelectedDate(); // Refresh habits after returning
            },
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HabitDetailScreen(
                  userId: widget.userId,
                  habit: habit,
                ),
              ),
            );
            _loadHabitsForSelectedDate(); // Refresh habits after returning
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => _changeDate(-1),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == '전체 습관 목록') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => HabitListScreen(userId: widget.userId)),
                );
                _loadHabitsForSelectedDate(); // Refresh habits after returning
              } else if (value == '태그 관리') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => TagManagementScreen(userId: widget.userId)),
                );
                _loadHabitsForSelectedDate(); // Refresh habits after returning
              }
            },
            itemBuilder: (BuildContext context) {
              return {'전체 습관 목록', '태그 관리'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _habits.isEmpty ? _buildEmptyView() : _buildHabitListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => HabitFormScreen(userId: widget.userId)),
          );
          _loadHabitsForSelectedDate(); // Refresh habits after returning from form
        },
        child: const Icon(Icons.add),
        tooltip: '새 습관 추가',
      ),
    );
  }
}
