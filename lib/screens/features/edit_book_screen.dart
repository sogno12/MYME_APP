import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/book_model.dart'; // ReadingStatus enum 임포트
import 'package:myme_app/utils/reading_status_utils.dart'; // 한국어 매핑 유틸 임포트

class EditBookScreen extends StatefulWidget {
  final int bookId;

  const EditBookScreen({super.key, required this.bookId});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _initialData;

  // 텍스트 컨트롤러
  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  ReadingStatus _selectedStatus = ReadingStatus.toRead; // 기본값 설정

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final data = await dbHelper.getBookById(widget.bookId);
    if (data != null) {
      setState(() {
        _initialData = data;
        _titleController.text = data[DatabaseHelper.columnTitle] ?? '';
        
        String authorsData = data[DatabaseHelper.columnAuthors] ?? '';
        try {
          // Try to parse it as a JSON list
          final List<dynamic> authorsList = jsonDecode(authorsData);
          _authorsController.text = authorsList.join(', ');
        } catch (e) {
          // If it's not a valid JSON, it's probably an old comma-separated string
          _authorsController.text = authorsData;
        }

        _totalPagesController.text = data[DatabaseHelper.columnTotalPages]?.toString() ?? '';
        _notesController.text = data[DatabaseHelper.columnNotes] ?? '';

        if (data[DatabaseHelper.columnManualStartDate] != null) {
          _selectedStartDate = DateTime.parse(data[DatabaseHelper.columnManualStartDate]);
          _startDateController.text = DateFormat('yyyy/MM/dd').format(_selectedStartDate!);
        }
        if (data[DatabaseHelper.columnManualEndDate] != null) {
          _selectedEndDate = DateTime.parse(data[DatabaseHelper.columnManualEndDate]);
          _endDateController.text = DateFormat('yyyy/MM/dd').format(_selectedEndDate!);
        }
        // 상태 로드
        _selectedStatus = ReadingStatus.values.firstWhere(
          (e) => e.name == data[DatabaseHelper.columnStatus],
          orElse: () => ReadingStatus.toRead, // 기본값
        );
      });
    }
  }

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

  Future<void> _showSaveConfirmationDialog() async {
    if (_formKey.currentState!.validate()) {
      final dateValidationError = _validateDates();
      if (dateValidationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dateValidationError), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('수정 저장'),
            content: const Text('변경사항을 저장하시겠습니까?'),
            actions: <Widget>[
              TextButton(
                child: const Text('취소'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('저장'),
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  _saveBookChanges();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _saveBookChanges() async {
      final now = DateTime.now().toIso8601String();

      // 저자 문자열을 처리하여 JSON 형식으로 변환
      final List<String> authorsList = _authorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final String authorsJson = jsonEncode(authorsList);

      final updatedBook = {
        DatabaseHelper.columnId: widget.bookId,
        DatabaseHelper.columnUpdatedAt: now,
        DatabaseHelper.columnTitle: _titleController.text,
        DatabaseHelper.columnAuthors: authorsJson, // JSON 형식으로 저장
        DatabaseHelper.columnTotalPages: int.tryParse(_totalPagesController.text) ?? 0,
        DatabaseHelper.columnNotes: _notesController.text,
        DatabaseHelper.columnManualStartDate: _selectedStartDate != null ? DateFormat('yyyy/MM/dd').format(_selectedStartDate!) : null,
        DatabaseHelper.columnManualEndDate: _selectedEndDate != null ? DateFormat('yyyy/MM/dd').format(_selectedEndDate!) : null,
        DatabaseHelper.columnStatus: _selectedStatus.name, // 선택된 상태 저장
        // 수정 시 변경되지 않는 값들도 포함해야 할 수 있음
        DatabaseHelper.columnCreatedAt: _initialData![DatabaseHelper.columnCreatedAt],
        DatabaseHelper.columnOwnerId: _initialData![DatabaseHelper.columnOwnerId],
        DatabaseHelper.columnCreatedBy: _initialData![DatabaseHelper.columnCreatedBy],
        DatabaseHelper.columnUpdatedBy: _initialData![DatabaseHelper.columnOwnerId], // 수정자는 현재 사용자로
      };

      await dbHelper.updateBook(updatedBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('책 정보가 수정되었습니다.')),
        );
        Navigator.of(context).pop(true); // true를 반환하여 상세화면 새로고침
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 정보 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveConfirmationDialog,
            tooltip: '저장',
          )
        ],
      ),
      body: _initialData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    // 독서 상태 드롭다운 추가
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