import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/habit_log_model.dart';
import 'package:uuid/uuid.dart';

class HabitLogFormScreen extends StatefulWidget {
  final int userId;
  final String habitId;
  final HabitLog? log;
  final DateTime? initialDate;

  const HabitLogFormScreen({Key? key, required this.userId, required this.habitId, this.log, this.initialDate}) : super(key: key);

  @override
  _HabitLogFormScreenState createState() => _HabitLogFormScreenState();
}

class _HabitLogFormScreenState extends State<HabitLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  late DateTime _selectedDate;
  late TextEditingController _memoController;
  late bool _isCompleted;
  late TextEditingController _timeValueController;
  late TextEditingController _percentageValueController;
  late TextEditingController _quantityValueController;

  bool get _isEditing => widget.log != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _selectedDate = widget.log!.date;
      _memoController = TextEditingController(text: widget.log!.memo);
      _isCompleted = widget.log!.isCompleted;
      _timeValueController = TextEditingController(text: widget.log!.timeValue?.toString());
      _percentageValueController = TextEditingController(text: widget.log!.percentageValue?.toString());
      _quantityValueController = TextEditingController(text: widget.log!.quantityValue?.toString());
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _memoController = TextEditingController();
      _isCompleted = true;
      _timeValueController = TextEditingController();
      _percentageValueController = TextEditingController();
      _quantityValueController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _timeValueController.dispose();
    _percentageValueController.dispose();
    _quantityValueController.dispose();
    super.dispose();
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
    }
  }

  Future<void> _saveLog() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final now = DateTime.now();
      final log = HabitLog(
        id: _isEditing ? widget.log!.id : uuid.v4(),
        habitId: widget.habitId,
        date: _selectedDate,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        isCompleted: _isCompleted,
        timeValue: int.tryParse(_timeValueController.text),
        percentageValue: int.tryParse(_percentageValueController.text),
        quantityValue: int.tryParse(_quantityValueController.text),
        ownerId: widget.userId,
        createdBy: _isEditing ? widget.log!.createdBy : widget.userId,
        updatedBy: widget.userId,
        createdAt: _isEditing ? widget.log!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await dbHelper.updateHabitLog(log);
      } else {
        await dbHelper.insertHabitLog(log);
      }

      Navigator.of(context).pop();
    }
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    final int? number = int.tryParse(value);
    if (number == null || number < 0) {
      return '0 이상의 숫자를 입력해주세요.';
    }
    return null;
  }

  String? _validatePercentage(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    final int? number = int.tryParse(value);
    if (number == null || number < 0 || number > 100) {
      return '0에서 100 사이의 숫자를 입력해주세요.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '로그 수정' : '새 로그 추가'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLog,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: const Text('날짜'),
              subtitle: Text(
                '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택 사항)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            CheckboxListTile(
              title: const Text('완료 여부'),
              value: _isCompleted,
              onChanged: (bool? newValue) {
                setState(() {
                  _isCompleted = newValue!;
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _timeValueController,
              decoration: const InputDecoration(
                labelText: '시간 (분) (선택 사항)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: _validatePositiveNumber,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _percentageValueController,
              decoration: const InputDecoration(
                labelText: '달성률 (%) (선택 사항)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: _validatePercentage,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _quantityValueController,
              decoration: const InputDecoration(
                labelText: '횟수 (선택 사항)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: _validatePositiveNumber,
            ),
          ],
        ),
      ),
    );
  }
}
