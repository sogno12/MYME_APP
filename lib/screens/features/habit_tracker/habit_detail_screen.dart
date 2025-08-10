import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/habit_model.dart';
import 'package:myme_app/models/habit_log_model.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_form_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_log_form_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final int userId;
  final Habit habit;

  const HabitDetailScreen({Key? key, required this.userId, required this.habit}) : super(key: key);

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Habit _currentHabit;
  List<HabitLog> _habitLogs = [];

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
    _loadHabitLogs();
  }

  Future<void> _loadHabitLogs() async {
    final logs = await dbHelper.getHabitLogsForHabit(_currentHabit.id);
    setState(() {
      _habitLogs = logs;
    });
  }

  Future<void> _editHabit() async {
    final updatedHabit = await Navigator.of(context).push<Habit?>(
      MaterialPageRoute(
        builder: (context) => HabitFormScreen(
          userId: widget.userId,
          habit: _currentHabit,
        ),
      ),
    );

    if (updatedHabit != null) {
      print('Habit updated: ${updatedHabit.title}'); // Debug print
      setState(() {
        _currentHabit = updatedHabit;
      });
    } else {
      print('Habit update cancelled or failed.'); // Debug print
    }
  }

  Future<void> _addOrEditLog({HabitLog? log}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitLogFormScreen(
          userId: widget.userId,
          habitId: _currentHabit.id,
          log: log,
        ),
      ),
    );
    _loadHabitLogs(); // Refresh logs after returning
  }

  Future<void> _deleteLog(String logId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그 삭제'),
          content: const Text('이 로그를 정말 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await dbHelper.deleteHabitLog(logId);
      _loadHabitLogs(); // Refresh logs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentHabit.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editHabit,
            tooltip: '습관 수정',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentHabit.emoji} ${_currentHabit.title}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentHabit.content.isNotEmpty ? _currentHabit.content : '내용 없음',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '시작일: ${_currentHabit.startDate.year}/${_currentHabit.startDate.month.toString().padLeft(2, '0')}/${_currentHabit.startDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (_currentHabit.endDate != null)
                  Text(
                    '종료일: ${_currentHabit.endDate!.year}/${_currentHabit.endDate!.month.toString().padLeft(2, '0')}/${_currentHabit.endDate!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                Text(
                  '추적 유형: ${_currentHabit.trackingType.toString().split('.').last}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (_currentHabit.goalUnit != null && _currentHabit.goalUnit!.isNotEmpty)
                  Text(
                    '목표 단위: ${_currentHabit.goalUnit}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: _currentHabit.tags.map((tag) => Chip(label: Text(tag.name))).toList(),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '로그 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _habitLogs.isEmpty
                ? const Center(
                    child: Text('기록된 로그가 없습니다.'),
                  )
                : ListView.builder(
                    itemCount: _habitLogs.length,
                    itemBuilder: (context, index) {
                      final log = _habitLogs[index];
                      return ListTile(
                        title: Text(
                          '${log.date.year}/${log.date.month.toString().padLeft(2, '0')}/${log.date.day.toString().padLeft(2, '0')}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (log.timeValue != null) Text('시간: ${log.timeValue}분'),
                            if (log.percentageValue != null) Text('달성률: ${log.percentageValue}%'),
                            if (log.quantityValue != null) Text('횟수: ${log.quantityValue}회'),
                            if (log.memo != null && log.memo!.isNotEmpty) Text('메모: ${log.memo}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _addOrEditLog(log: log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteLog(log.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditLog(),
        child: const Icon(Icons.add),
        tooltip: '새 로그 추가',
      ),
    );
  }
}
