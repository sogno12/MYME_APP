import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/book_model.dart'; // ReadingStatus enum 임포트
import 'package:myme_app/utils/reading_status_utils.dart'; // 한국어 매핑 유틸 임포트

class AddBookScreen extends StatefulWidget {
  final int currentUserId;

  const AddBookScreen({super.key, required this.currentUserId});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _bookData; // 책 정보 저장
  bool _isLoadingBook = true; // 책 정보 로딩 상태

  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  ReadingStatus _selectedStatus = ReadingStatus.toRead; // 기본 상태: 읽을 책

  @override
  void initState() {
    super.initState();
    _loadBookData(); // 책 정보 로딩 (total_pages를 위해)
  }

  void _loadBookData() async {
    // AddBookScreen에서는 bookId가 없으므로, 이 함수는 total_pages를 가져오지 않습니다.
    // 하지만 _isLoadingBook 상태 관리를 위해 남겨둡니다.
    setState(() {
      _isLoadingBook = false; // 로딩 완료로 설정
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _totalPagesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
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
      final newBook = {
        DatabaseHelper.columnCreatedAt: now,
        DatabaseHelper.columnUpdatedAt: now,
        DatabaseHelper.columnOwnerId: widget.currentUserId,
        DatabaseHelper.columnCreatedBy: widget.currentUserId,
        DatabaseHelper.columnUpdatedBy: widget.currentUserId,
        DatabaseHelper.columnTitle: _titleController.text,
        DatabaseHelper.columnAuthors: _authorsController.text,
        DatabaseHelper.columnTotalPages: int.tryParse(_totalPagesController.text) ?? 0,
        DatabaseHelper.columnStatus: _selectedStatus.name, // 선택된 상태 저장
        DatabaseHelper.columnManualStartDate: _selectedStartDate != null ? DateFormat('yyyy/MM/dd').format(_selectedStartDate!) : null,
        DatabaseHelper.columnManualEndDate: _selectedEndDate != null ? DateFormat('yyyy/MM/dd').format(_selectedEndDate!) : null,
      };

      await dbHelper.insertBook(newBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로운 책을 추가했습니다.')),
        );
        Navigator.of(context).pop(true); // true를 반환하여 목록 새로고침을 알림
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AddBookScreen에서는 total_pages를 사용하지 않으므로 로딩 상태를 제거합니다.
    // if (_isLoadingBook) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('새 책 추가')),
    //     body: const Center(child: const CircularProgressIndicator()),
    //   );
    // }

    // if (_bookData == null) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('새 책 추가')),
    //     body: const Center(child: const Text('책 정보를 불러올 수 없습니다.')),
    //   );
    // }

    // final int totalPages = _bookData![DatabaseHelper.columnTotalPages] ?? 0; // 사용하지 않음

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 책 추가'),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '책 제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _authorsController,
                decoration: const InputDecoration(labelText: '저자 (쉼표로 구분)'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '저자를 입력해주세요.';
                  }
                  return null;
                },
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
                decoration: const InputDecoration(
                  labelText: '독서 시작일 (선택)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: '독서 종료일 (선택)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, isStartDate: false),
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