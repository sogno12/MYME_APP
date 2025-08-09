import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/book_model.dart';
import 'package:myme_app/utils/reading_status_utils.dart';

class AddManualBookScreen extends StatefulWidget {
  final int userId;

  const AddManualBookScreen({super.key, required this.userId});

  @override
  State<AddManualBookScreen> createState() => _AddManualBookScreenState();
}

class _AddManualBookScreenState extends State<AddManualBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  // Text controllers
  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  ReadingStatus _selectedStatus = ReadingStatus.toRead;

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _totalPagesController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          _startDateController.text = DateFormat('yyyy/MM/dd').format(picked);
        } else {
          _selectedEndDate = picked;
          _endDateController.text = DateFormat('yyyy/MM/dd').format(picked);
        }
      });
    }
  }

  String? _validateDates() {
    if (_selectedEndDate != null && _selectedStartDate == null) {
      return '독서 시작일 없이 종료일을 설정할 수 없습니다.';
    }
    if (_selectedStartDate != null && _selectedEndDate != null && _selectedStartDate!.isAfter(_selectedEndDate!)) {
      return '독서 시작일은 종료일보다 빠르거나 같아야 합니다.';
    }
    return null;
  }

  void _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final dateValidationError = _validateDates();
      if (dateValidationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dateValidationError), backgroundColor: Colors.red),
        );
        return;
      }

      final now = DateTime.now().toIso8601String();
      final List<String> authorsList = _authorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final String authorsJson = jsonEncode(authorsList);

      final newBook = {
        DatabaseHelper.columnTitle: _titleController.text,
        DatabaseHelper.columnAuthors: authorsJson,
        DatabaseHelper.columnTotalPages: int.tryParse(_totalPagesController.text) ?? 0,
        DatabaseHelper.columnStatus: _selectedStatus.name,
        DatabaseHelper.columnNotes: _notesController.text,
        DatabaseHelper.columnManualStartDate: _selectedStartDate?.toIso8601String(),
        DatabaseHelper.columnManualEndDate: _selectedEndDate?.toIso8601String(),
        DatabaseHelper.columnCreatedAt: now,
        DatabaseHelper.columnUpdatedAt: now,
        DatabaseHelper.columnOwnerId: widget.userId,
        DatabaseHelper.columnCreatedBy: widget.userId,
        DatabaseHelper.columnUpdatedBy: widget.userId,
      };

      await dbHelper.insertBook(newBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 책이 추가되었습니다.')),
        );
        Navigator.of(context).pop(true); // Return true to refresh the list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 책 수동 추가'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBook,
            tooltip: '저장',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '책 제목'),
                validator: (value) => (value == null || value.isEmpty) ? '책 제목을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _authorsController,
                decoration: const InputDecoration(labelText: '저자 (쉼표로 구분)'),
                validator: (value) => (value == null || value.isEmpty) ? '저자를 입력해주세요.' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _totalPagesController,
                decoration: const InputDecoration(labelText: '전체 페이지 수'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                 validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '전체 페이지 수를 입력해주세요.';
                        }
                        final int? pages = int.tryParse(value);
                        if (pages == null || pages <= 0) {
                          return '유효한 페이지 숫자를 입력해주세요 (1 이상).';
                        }
                        return null;
                      },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(labelText: '독서 시작일 (선택)', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(labelText: '독서 완료일 (선택)', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '메모'),
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<ReadingStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: '독서 상태'),
                items: ReadingStatus.values.map((ReadingStatus status) {
                  return DropdownMenuItem<ReadingStatus>(
                    value: status,
                    child: Text(readingStatusKorean[status] ?? status.name),
                  );
                }).toList(),
                onChanged: (ReadingStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
