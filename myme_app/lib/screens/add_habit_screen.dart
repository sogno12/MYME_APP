// lib/screens/add_habit_screen.dart

import 'package:intl/intl.dart'; // Add this line
import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:myme_app/services/tag_service.dart';
import 'package:myme_app/models/tag.dart';
import 'package:uuid/uuid.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // 기존 습관을 수정할 경우 전달받을 Habit 객체

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _emojiController = TextEditingController(text: '😊');

  // --- State Variables ---
  HabitTrackingType _selectedTrackingType = HabitTrackingType.checkOnly;
  bool _showLogEditorOnCheck = false; // <<<< 오류의 원인이었던 변수 선언
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _selectedTagIds = [];

  final HabitService _habitService = HabitService();
  final TagService _tagService = TagService();

  @override
  void initState() {
    super.initState();
    _loadTags(); // 태그 목록을 미리 로드
    if (widget.habit != null) {
      _titleController.text = widget.habit!.title;
      _contentController.text = widget.habit!.content ?? '';
      _emojiController.text = widget.habit!.emoji;
      _selectedTrackingType = widget.habit!.trackingType;
      _showLogEditorOnCheck = widget.habit!.showLogEditorOnCheck;
      _startDate = widget.habit!.startDate;
      _endDate = widget.habit!.endDate;
      _selectedTagIds = List.from(widget.habit!.tagIds); // 기존 태그 ID 로드
    }
  }

  List<Tag> _allTags = []; // 모든 태그를 저장할 리스트

  Future<void> _loadTags() async {
    try {
      final tags = await _tagService.getAllTags();
      setState(() {
        _allTags = tags;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tags: \$e')),
      );
    }
  }

  void _showTagSelectionDialog() async {
    final List<Tag> availableTags = await _tagService.getAllTags();
    final List<String> tempSelectedTagIds = List.from(_selectedTagIds);
    final TextEditingController _newTagController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Tags'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 기존 태그 선택
                    Wrap(
                      spacing: 8.0,
                      children: availableTags.map((tag) {
                        final isSelected = tempSelectedTagIds.contains(tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                tempSelectedTagIds.add(tag.id);
                              } else {
                                tempSelectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    // 새 태그 추가
                    TextField(
                      controller: _newTagController, // 새 태그 입력 컨트롤러
                      decoration: InputDecoration(
                        labelText: 'New Tag Name',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final newTagName = _newTagController.text.trim();
                            if (newTagName.isNotEmpty) {
                              final newTag = Tag(id: const Uuid().v4(), name: newTagName);
                              await _tagService.addTag(newTag);
                              setDialogState(() {
                                availableTags.add(newTag);
                                tempSelectedTagIds.add(newTag.id);
                                _newTagController.clear(); // 입력 필드 비우기
                                _loadTags(); // 전체 태그 목록 새로고침
                              });
                            }
                          },
                        ),
                      ),
                      onSubmitted: (newTagName) async {
                        if (newTagName.isNotEmpty) {
                          final newTag = Tag(id: const Uuid().v4(), name: newTagName);
                          await _tagService.addTag(newTag);
                          setDialogState(() {
                            availableTags.add(newTag);
                            tempSelectedTagIds.add(newTag.id);
                            _newTagController.clear(); // 입력 필드 비우기
                            _loadTags(); // 전체 태그 목록 새로고침
                          });
                        }
                      },
                    ),
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
                      _selectedTagIds = List.from(tempSelectedTagIds);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, {bool isStartDate = true}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        if (isStartDate) {
          _startDate = dateOnly;
        } else {
          _endDate = dateOnly;
        }
      });
    }
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endDate = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day) : null;

      if (widget.habit == null) {
        // 새 습관 추가
        final newHabit = Habit(
          id: const Uuid().v4(),
          title: _titleController.text,
          content: _contentController.text.isEmpty ? '' : _contentController.text,
          emoji: _emojiController.text,
          startDate: startDate,
          endDate: endDate,
          trackingType: _selectedTrackingType,
          showLogEditorOnCheck: _showLogEditorOnCheck,
          tagIds: _selectedTagIds,
        );
        _habitService.addHabit(newHabit).then((_) {
          Navigator.pop(context, true);
        });
      } else {
        // 기존 습관 업데이트
        final updatedHabit = widget.habit!.copyWith(
          title: _titleController.text,
          content: _contentController.text.isEmpty ? '' : _contentController.text,
          emoji: _emojiController.text,
          startDate: startDate,
          endDate: endDate,
          trackingType: _selectedTrackingType,
          showLogEditorOnCheck: _showLogEditorOnCheck,
          tagIds: _selectedTagIds,
        );
        _habitService.updateHabit(updatedHabit).then((_) {
          Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add New Habit' : 'Edit Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHabit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content (Optional)'),
              ),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(labelText: 'Emoji'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter an emoji' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<HabitTrackingType>(
                value: _selectedTrackingType,
                decoration: const InputDecoration(labelText: 'Default Tracking Type'),
                items: HabitTrackingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTrackingType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text("Start Date: ${DateFormat('yyyy/MM/dd').format(_startDate)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              ListTile(
                title: Text("End Date: ${DateFormat('yyyy/MM/dd').format(_endDate ?? DateTime.now())}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: false),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Open editor on check'),
                subtitle: const Text('For detailed logging instead of a simple check.'),
                value: _showLogEditorOnCheck, // <<<< UI에서 변수 사용
                onChanged: (bool value) {
                  setState(() {
                    _showLogEditorOnCheck = value; // <<<< UI에서 변수 값 변경
                  });
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Tags'),
                subtitle: _selectedTagIds.isEmpty
                    ? const Text('No tags selected')
                    : Wrap(
                        spacing: 8.0,
                        children: _selectedTagIds.map((tagId) {
                          final tag = _allTags.firstWhere((t) => t.id == tagId, orElse: () => Tag(id: tagId, name: 'Unknown Tag'));
                          return Chip(label: Text(tag.name));
                        }).toList(),
                      ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showTagSelectionDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}