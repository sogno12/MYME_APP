
// lib/screens/all_habits_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:myme_app/services/tag_service.dart';
import 'package:myme_app/models/tag.dart';
import 'package:myme_app/screens/add_habit_screen.dart'; // 습관 추가/수정 화면
import 'package:myme_app/screens/habit_log_list_screen.dart'; // HabitLogListScreen 추가

class AllHabitsScreen extends StatefulWidget {
  const AllHabitsScreen({super.key});

  @override
  State<AllHabitsScreen> createState() => _AllHabitsScreenState();
}

class _AllHabitsScreenState extends State<AllHabitsScreen> {
  final HabitService _habitService = HabitService();
  final TagService _tagService = TagService();
  List<Habit> _allHabits = [];
  List<Tag> _allTags = []; // 모든 태그를 저장할 리스트
  bool _isLoading = true;

  List<String> _selectedFilterTagIds = []; // 필터링에 사용될 태그 ID 목록
  String _searchQuery = ''; // 검색어
  bool _isSearching = false; // 검색 바 표시 여부

  @override
  void initState() {
    super.initState();
    _loadAllHabits();
  }

  Future<void> _loadAllHabits() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitService.getAllHabits();
      final tags = await _tagService.getAllTags();

      List<Habit> filteredHabits = habits.where((habit) {
        // 제목 필터링
        final matchesSearchQuery = _searchQuery.isEmpty ||
            habit.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // 태그 필터링
        final matchesTags = _selectedFilterTagIds.isEmpty ||
            _selectedFilterTagIds.any((tagId) => habit.tagIds.contains(tagId));

        return matchesSearchQuery && matchesTags;
      }).toList();

      setState(() {
        _allHabits = filteredHabits;
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load habits: \$e')),
      );
    }
  }

  void _navigateToAddHabitScreen({Habit? habit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddHabitScreen(habit: habit)),
    );
    if (result == true) {
      _loadAllHabits(); // 습관이 추가/수정되었으면 목록 새로고침
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = ''; // 검색 바 닫을 때 검색어 초기화
        _loadAllHabits();
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
                      _loadAllHabits(); // 필터 적용 후 데이터 새로고침
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

  Future<void> _deleteHabit(String habitId) async {
    // 삭제 확인 다이얼로그
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text('Are you sure you want to delete this habit? This action cannot be undone.'),
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
        await _habitService.deleteHabit(habitId);
        _loadAllHabits(); // 삭제 후 목록 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete habit: \$e')),
        );
      }
    }
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
                    _loadAllHabits();
                  });
                },
              )
            : const Text('All Habits'),
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddHabitScreen(), // 새 습관 추가
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allHabits.isEmpty
              ? const Center(
                  child: Text(
                    'No habits found. Tap "+" to add one!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _allHabits.length,
                  itemBuilder: (context, index) {
                    final habit = _allHabits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Text(habit.emoji, style: const TextStyle(fontSize: 28)),
                        title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.content.isEmpty ? 'No description' : habit.content),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _navigateToAddHabitScreen(habit: habit), // 습관 수정
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteHabit(habit.id), // 습관 삭제
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HabitLogListScreen(habit: habit)),
                          );
                        }, // 탭하여 로그 목록 보기
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddHabitScreen(), // 새 습관 추가
        child: const Icon(Icons.add),
      ),
    );
  }
}
