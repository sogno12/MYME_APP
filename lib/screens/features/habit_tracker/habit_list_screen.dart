import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/habit_model.dart';
import 'package:myme_app/models/tag_model.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_form_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/habit_detail_screen.dart';
import 'package:myme_app/screens/features/habit_tracker/tag_management_screen.dart';

class HabitListScreen extends StatefulWidget {
  final int userId;
  const HabitListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HabitListScreenState createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Habit> _allHabits = [];
  List<Habit> _filteredHabits = [];
  late TextEditingController _searchController;
  List<Tag> _selectedTags = [];
  List<Tag> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadHabits();
    _loadAvailableTags();

    _searchController.addListener(() {
      _filterHabits();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final habits = await dbHelper.getAllHabits(widget.userId);
    setState(() {
      _allHabits = habits;
    });
    _filterHabits();
  }

  Future<void> _loadAvailableTags() async {
    final tags = await dbHelper.getAllTags(widget.userId);
    setState(() {
      _availableTags = tags;
    });
  }

  void _filterHabits() {
    List<Habit> tempHabits = _allHabits;

    // Search by title
    if (_searchController.text.isNotEmpty) {
      tempHabits = tempHabits.where((habit) {
        return habit.title.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Filter by tags
    if (_selectedTags.isNotEmpty) {
      tempHabits = tempHabits.where((habit) {
        return _selectedTags.every((selectedTag) {
          return habit.tags.any((habitTag) => habitTag.id == selectedTag.id);
        });
      }).toList();
    }

    setState(() {
      _filteredHabits = tempHabits;
    });
  }

  Future<void> _deleteHabit(Habit habit) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('습관 삭제'),
          content: Text('${habit.title} 습관을 정말 삭제하시겠습니까?\n관련된 모든 로그도 삭제됩니다.'),
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
      await dbHelper.deleteHabit(habit.id);
      _loadHabits(); // Refresh habits
    }
  }

  void _showTagFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Tag> tempSelectedTags = List.from(_selectedTags);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('태그 필터'),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  children: _availableTags.map((tag) {
                    final isSelected = tempSelectedTags.any((t) => t.id == tag.id);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            tempSelectedTags.add(tag);
                          } else {
                            tempSelectedTags.removeWhere((t) => t.id == tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags = tempSelectedTags;
                    });
                    Navigator.of(context).pop();
                    _filterHabits(); // Apply filter
                  },
                  child: const Text('적용'),
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
        title: const Text('전체 습관 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showTagFilterDialog,
            tooltip: '태그 필터',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HabitFormScreen(userId: widget.userId)),
              );
              _loadHabits(); // Refresh habits after returning
            },
            tooltip: '새 습관 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '습관 검색',
                hintText: '제목으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterHabits();
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8.0,
                  children: _selectedTags.map((tag) {
                    return Chip(
                      label: Text(tag.name),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.removeWhere((t) => t.id == tag.id);
                        });
                        _filterHabits();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: _filteredHabits.isEmpty
                ? const Center(
                    child: Text('표시할 습관이 없습니다.'),
                  )
                : ListView.builder(
                    itemCount: _filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = _filteredHabits[index];
                      return ListTile(
                        leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(habit.title),
                        subtitle: Text(habit.content.isNotEmpty ? habit.content : '내용 없음'),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => HabitDetailScreen(
                                userId: widget.userId,
                                habit: habit,
                              ),
                            ),
                          );
                          _loadHabits(); // Refresh habits after returning
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => HabitFormScreen(
                                      userId: widget.userId,
                                      habit: habit,
                                    ),
                                  ),
                                );
                                _loadHabits(); // Refresh habits after returning
                                _loadAvailableTags(); // Refresh available tags after returning
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteHabit(habit),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
