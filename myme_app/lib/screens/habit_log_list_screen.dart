// lib/screens/habit_log_list_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/models/habit_log.dart';
import 'package:myme_app/models/tag.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:myme_app/services/tag_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class HabitLogListScreen extends StatefulWidget {
  final Habit habit;

  const HabitLogListScreen({super.key, required this.habit});

  @override
  State<HabitLogListScreen> createState() => _HabitLogListScreenState();
}

enum LogSortOption {
  logDateAsc,
  logDateDesc,
  createdAtAsc,
  createdAtDesc,
  updatedAtAsc,
  updatedAtDesc,
}

class _HabitLogListScreenState extends State<HabitLogListScreen> {
  final HabitService _habitService = HabitService();
  final TagService _tagService = TagService();
  List<HabitLog> _habitLogs = [];
  List<Tag> _allTags = [];
  bool _isLoading = true;
  LogSortOption _sortOption = LogSortOption.logDateDesc; // 기본 정렬 옵션

  @override
  void initState() {
    super.initState();
    _loadLogsAndTags();
  }

  Future<void> _loadLogsAndTags() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _habitService.getLogsForHabit(widget.habit.id);
      final tags = await _tagService.getAllTags();

      // 정렬 로직 적용
      logs.sort((a, b) {
        switch (_sortOption) {
          case LogSortOption.logDateAsc:
            return a.date.compareTo(b.date);
          case LogSortOption.logDateDesc:
            return b.date.compareTo(a.date);
          case LogSortOption.createdAtAsc:
            return (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
          case LogSortOption.createdAtDesc:
            return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
          case LogSortOption.updatedAtAsc:
            return (a.updatedAt ?? DateTime(0)).compareTo(b.updatedAt ?? DateTime(0));
          case LogSortOption.updatedAtDesc:
            return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
        }
      });

      setState(() {
        _habitLogs = logs;
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load logs: \$e')),
      );
    }
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

  Future<void> _showLogEditorDialog(HabitLog? existingLog) async {
    final isNewLog = existingLog == null;
    final logToEdit = existingLog ?? HabitLog(id: const Uuid().v4(), habitId: widget.habit.id, date: DateTime.now());

    final timeController = TextEditingController(text: logToEdit.timeValue?.toString() ?? '');
    final percentController = TextEditingController(text: logToEdit.percentageValue?.toString() ?? '');
    final quantityController = TextEditingController(text: logToEdit.quantityValue?.toString() ?? '');
    final memoController = TextEditingController(text: logToEdit.memo ?? '');
    bool isCompleted = logToEdit.isCompleted;
    DateTime selectedDate = logToEdit.date; // 로그 날짜 선택을 위한 변수

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isNewLog ? 'Add Log' : 'Edit Log'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("Date: ${DateFormat('yyyy/MM/dd').format(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = DateTime(picked.year, picked.month, picked.day);
                          });
                        }
                      },
                    ),
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
                      habitId: widget.habit.id,
                      date: selectedDate, // 선택된 날짜 사용
                      isCompleted: isCompleted,
                      timeValue: int.tryParse(timeController.text),
                      percentageValue: int.tryParse(percentController.text),
                      quantityValue: int.tryParse(quantityController.text),
                      memo: memoController.text,
                    );
                    _habitService.addOrUpdateLog(updatedLog).then((_) {
                      Navigator.pop(context);
                      _loadLogsAndTags();
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

  Future<void> _deleteLog(String logId, DateTime logDate) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _habitService.deleteLog(widget.habit.id, logDate);
        _loadLogsAndTags();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete log: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<LogSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (LogSortOption result) {
              setState(() {
                _sortOption = result;
                _loadLogsAndTags(); // 정렬 옵션 변경 시 로그 새로고침
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<LogSortOption>>[
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.logDateDesc,
                child: Text('Log Date (Newest First)'),
              ),
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.logDateAsc,
                child: Text('Log Date (Oldest First)'),
              ),
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.createdAtDesc,
                child: Text('Created At (Newest First)'),
              ),
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.createdAtAsc,
                child: Text('Created At (Oldest First)'),
              ),
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.updatedAtDesc,
                child: Text('Updated At (Newest First)'),
              ),
              const PopupMenuItem<LogSortOption>(
                value: LogSortOption.updatedAtAsc,
                child: Text('Updated At (Oldest First)'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 습관 상세 정보 영역
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.habit.emoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.habit.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.habit.content.isEmpty ? 'No description' : widget.habit.content,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      if (widget.habit.tagIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 6.0,
                            runSpacing: 0.0,
                            children: widget.habit.tagIds.map((tagId) {
                              final tag = _allTags.firstWhere(
                                (t) => t.id == tagId,
                                orElse: () => Tag(id: tagId, name: 'Unknown'),
                              );
                              return Chip(
                                label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        'Logs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // 로그 목록 영역
                Expanded(
                  child: _habitLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No logs yet. Tap "+" to add your first log!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _habitLogs.length,
                          itemBuilder: (context, index) {
                            final log = _habitLogs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(DateFormat('yyyy/MM/dd').format(log.date)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getLogSummary(log)),
                                    if (log.createdAt != null)
                                      Text(
                                        'Created: ${DateFormat('yyyy/MM/dd HH:mm').format(log.createdAt!)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    if (log.updatedAt != null)
                                      Text(
                                        'Updated: ${DateFormat('yyyy/MM/dd HH:mm').format(log.updatedAt!)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showLogEditorDialog(log),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteLog(log.id, log.date),
                                    ),
                                  ],
                                ),
                                onTap: () => _showLogEditorDialog(log),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogEditorDialog(null), // 새 로그 추가
        child: const Icon(Icons.add),
      ),
    );
  }
}