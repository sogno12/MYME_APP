// lib/screens/todays_habits_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/models/habit_log.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:myme_app/services/tag_service.dart';
import 'package:myme_app/models/tag.dart';
import 'package:myme_app/screens/add_habit_screen.dart';
import 'package:myme_app/screens/all_habits_screen.dart';
import 'package:myme_app/screens/all_tags_screen.dart';
import 'package:uuid/uuid.dart';

class TodaysHabitsScreen extends StatefulWidget {
  const TodaysHabitsScreen({super.key});

  @override
  State<TodaysHabitsScreen> createState() => _TodaysHabitsScreenState();
}

class _TodaysHabitsScreenState extends State<TodaysHabitsScreen> {
  final HabitService _habitService = HabitService();
  final TagService _tagService = TagService();
  
  List<Habit> _todaysHabits = [];
  Map<String, HabitLog> _todaysLogs = {}; // <habitId, HabitLog>
  List<Tag> _allTags = []; // 모든 태그를 저장할 리스트
  bool _isLoading = true;

  List<String> _selectedFilterTagIds = []; // 필터링에 사용될 태그 ID 목록
  String _searchQuery = ''; // 검색어
  bool _isSearching = false; // 검색 바 표시 여부

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allHabits = await _habitService.getTodaysHabits();
      final logs = await _habitService.getLogsForDate(DateTime.now());
      final tags = await _tagService.getAllTags();

      List<Habit> filteredHabits = allHabits.where((habit) {
        // 제목 필터링
        final matchesSearchQuery = _searchQuery.isEmpty ||
            habit.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // 태그 필터링
        final matchesTags = _selectedFilterTagIds.isEmpty ||
            _selectedFilterTagIds.any((tagId) => habit.tagIds.contains(tagId));

        return matchesSearchQuery && matchesTags;
      }).toList();

      setState(() {
        _todaysHabits = filteredHabits;
        _todaysLogs = {for (var log in logs) log.habitId: log};
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: \$e')),
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = ''; // 검색 바 닫을 때 검색어 초기화
        _loadData();
      }
    });
  }

  Future<void> _showTagFilterDialog() async {
    final List<String> tempSelectedTagIds = List.from(_selectedFilterTagIds);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Tags'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempSelectedTagIds.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    ..._allTags.map((tag) {
                      final isSelected = tempSelectedTagIds.contains(tag.id);
                      return CheckboxListTile(
                        title: Text(tag.name),
                        value: isSelected,
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              tempSelectedTagIds.add(tag.id);
                            } else {
                              tempSelectedTagIds.remove(tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilterTagIds = List.from(tempSelectedTagIds);
                      _loadData(); // 필터 적용 후 데이터 새로고침
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: _isSearching
            ? TextField(
                decoration: const InputDecoration(
                  hintText: 'Search habits...',
                  border: InputBorder.none,
                ),
                autofocus: true,
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                    _loadData();
                  });
                },
              )
            : const Text("Today's Habits"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilterTagIds.isNotEmpty ? Colors.blue : null,
            ),
            onPressed: _showTagFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              if (result == 'all_habits') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllHabitsScreen()),
                );
              } else if (result == 'all_tags') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllTagsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'all_habits',
                child: Text('All Habits'),
              ),
              const PopupMenuItem<String>(
                value: 'all_tags',
                child: Text('Manage Tags'),
              ),
            ],
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log != null) Text(_getLogSummary(log)),
              if (habit.tagIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 0.0,
                    children: habit.tagIds.map((tagId) {
                      final tag = _allTags.firstWhere(
                        (t) => t.id == tagId,
                        orElse: () => Tag(id: tagId, name: 'Unknown'),
                      );
                      return Chip(
                        label: Text(tag.name, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
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