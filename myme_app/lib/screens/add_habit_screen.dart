// lib/screens/add_habit_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/habit.dart';
import 'package:myme_app/services/habit_service.dart';
import 'package:uuid/uuid.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

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

  final HabitService _habitService = HabitService();

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

      final newHabit = Habit(
        id: const Uuid().v4(),
        title: _titleController.text,
        content: _contentController.text,
        emoji: _emojiController.text,
        startDate: startDate,
        endDate: endDate,
        trackingType: _selectedTrackingType,
        showLogEditorOnCheck: _showLogEditorOnCheck, // <<<< 저장 로직에 변수 사용
      );

      _habitService.addHabit(newHabit).then((_) {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
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
                title: Text("Start Date: ${_startDate.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              ListTile(
                title: Text("End Date: ${_endDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}"),
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
            ],
          ),
        ),
      ),
    );
  }
}