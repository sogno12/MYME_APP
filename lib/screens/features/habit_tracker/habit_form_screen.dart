import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/habit_model.dart';
import 'package:myme_app/models/tag_model.dart';
import 'package:uuid/uuid.dart';

class HabitFormScreen extends StatefulWidget {
  final int userId;
  final Habit? habit;

  const HabitFormScreen({Key? key, required this.userId, this.habit}) : super(key: key);

  @override
  _HabitFormScreenState createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _emojiController;
  late TextEditingController _goalUnitController;

  late DateTime _startDate;
  DateTime? _endDate;
  late HabitTrackingType _trackingType;
  late bool _showLogEditorOnCheck;
  List<Tag> _selectedTags = [];
  List<Tag> _availableTags = [];

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();

    if (_isEditing) {
      _titleController = TextEditingController(text: widget.habit!.title);
      _contentController = TextEditingController(text: widget.habit!.content);
      _emojiController = TextEditingController(text: widget.habit!.emoji);
      _startDate = widget.habit!.startDate;
      _endDate = widget.habit!.endDate;
      _trackingType = widget.habit!.trackingType;
      _goalUnitController = TextEditingController(text: widget.habit!.goalUnit);
      _showLogEditorOnCheck = widget.habit!.showLogEditorOnCheck;
      _selectedTags = List.from(widget.habit!.tags);
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _emojiController = TextEditingController(text: '😊');
      _startDate = DateTime.now();
      _endDate = null;
      _trackingType = HabitTrackingType.checkOnly;
      _goalUnitController = TextEditingController();
      _showLogEditorOnCheck = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _emojiController.dispose();
    _goalUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    final tags = await dbHelper.getAllTags(widget.userId);
    setState(() {
      _availableTags = tags;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate.isAfter(_endDate!)) {
            _endDate = _startDate; // 시작일이 종료일보다 늦으면 종료일을 시작일로 조정
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate!)) {
            _startDate = _endDate!; // 종료일이 시작일보다 빠르면 시작일을 종료일로 조정
          }
        }
      });
    }
  }

  void _showTagSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Tag> tempSelectedTags = List.from(_selectedTags);
        TextEditingController newTagController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('태그 선택 및 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
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
                    const Divider(),
                    TextField(
                      controller: newTagController,
                      decoration: InputDecoration(
                        labelText: '새 태그 추가',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final tagName = newTagController.text.trim();
                            if (tagName.isNotEmpty && !_availableTags.any((t) => t.name == tagName)) {
                              final newTag = Tag(
                                id: uuid.v4(),
                                name: tagName,
                                ownerId: widget.userId,
                                createdBy: widget.userId,
                                updatedBy: widget.userId,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              await dbHelper.insertTag(newTag);
                              newTagController.clear();
                              await _loadAvailableTags(); // Refresh available tags
                              setState(() {
                                tempSelectedTags.add(newTag);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
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
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {}); // Rebuild the main screen to reflect selected tags
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final now = DateTime.now();
      final habit = Habit(
        id: _isEditing ? widget.habit!.id : uuid.v4(),
        title: _titleController.text,
        content: _contentController.text,
        emoji: _emojiController.text,
        startDate: _startDate,
        endDate: _endDate,
        trackingType: _trackingType,
        goalUnit: _goalUnitController.text.isEmpty ? null : _goalUnitController.text,
        showLogEditorOnCheck: _showLogEditorOnCheck,
        tags: _selectedTags,
        ownerId: widget.userId,
        createdBy: _isEditing ? widget.habit!.createdBy : widget.userId,
        updatedBy: widget.userId,
        createdAt: _isEditing ? widget.habit!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await dbHelper.updateHabit(habit);
      } else {
        await dbHelper.insertHabit(habit);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '습관 수정' : '새 습관 추가'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHabit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '습관 제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '습관 제목을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용 (선택 사항)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: '이모지 (예: 😊)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('시작일'),
              subtitle: Text(
                '${_startDate.year}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: const Text('종료일 (선택 사항)'),
              subtitle: Text(
                _endDate == null
                    ? '선택 안 함'
                    : '${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16.0),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '추적 유형',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HabitTrackingType>(
                  value: _trackingType,
                  onChanged: (HabitTrackingType? newValue) {
                    setState(() {
                      _trackingType = newValue!;
                    });
                  },
                  items: HabitTrackingType.values.map((type) {
                    String text;
                    switch (type) {
                      case HabitTrackingType.checkOnly:
                        text = '체크만';
                        break;
                      case HabitTrackingType.time:
                        text = '시간 (분)';
                        break;
                      case HabitTrackingType.percentage:
                        text = '백분율 (%)';
                        break;
                      case HabitTrackingType.quantity:
                        text = '횟수';
                        break;
                    }
                    return DropdownMenuItem(value: type, child: Text(text));
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_trackingType != HabitTrackingType.checkOnly)
              TextFormField(
                controller: _goalUnitController,
                decoration: const InputDecoration(
                  labelText: '목표 단위 (예: 분, %, 회)',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16.0),
            CheckboxListTile(
              title: const Text('체크 시 로그 편집창 표시'),
              value: _showLogEditorOnCheck,
              onChanged: (bool? newValue) {
                setState(() {
                  _showLogEditorOnCheck = newValue!;
                });
              },
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: _showTagSelectionDialog,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '태그',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Wrap(
                  spacing: 8.0,
                  children: _selectedTags.isEmpty
                      ? [const Text('태그를 선택하거나 추가하세요', style: TextStyle(color: Colors.grey))]
                      : _selectedTags.map((tag) => Chip(label: Text(tag.name))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
