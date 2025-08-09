import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';

class AddReadLogScreen extends StatefulWidget {
  final int bookId;

  const AddReadLogScreen({super.key, required this.bookId});

  @override
  State<AddReadLogScreen> createState() => _AddReadLogScreenState();
}

class _AddReadLogScreenState extends State<AddReadLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _bookData; // 책 정보 저장
  bool _isLoadingBook = true; // 책 정보 로딩 상태

  final _readingDateController = TextEditingController();
  final _endPageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _moodController = TextEditingController();

  DateTime? _selectedReadingDate;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  void _loadBookData() async {
    final book = await dbHelper.getBookById(widget.bookId);
    setState(() {
      _bookData = book;
      _isLoadingBook = false;
    });
  }

  @override
  void dispose() {
    _readingDateController.dispose();
    _endPageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReadingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedReadingDate = picked;
        _readingDateController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  void _saveReadLog() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedReadingDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('독서 날짜를 선택해주세요.'), backgroundColor: Colors.red),
        );
        return;
      }

      final now = DateTime.now().toIso8601String();
      final int endPage = int.tryParse(_endPageController.text) ?? 0;
      final int totalPages = _bookData![DatabaseHelper.columnTotalPages] ?? 0;
      final String currentBookStatus = _bookData![DatabaseHelper.columnStatus] ?? '';

      final newLog = {
        DatabaseHelper.columnCreatedAt: now,
        DatabaseHelper.columnUpdatedAt: now,
        DatabaseHelper.columnOwnerId: 1, // TODO: 실제 사용자 ID로 변경
        DatabaseHelper.columnCreatedBy: 1, // TODO: 실제 사용자 ID로 변경
        DatabaseHelper.columnUpdatedBy: 1, // TODO: 실제 사용자 ID로 변경
        DatabaseHelper.columnBookId: widget.bookId,
        DatabaseHelper.columnReadingDate: DateFormat('yyyy/MM/dd').format(_selectedReadingDate!), // 날짜 형식 통일
        DatabaseHelper.columnEndPage: endPage,
        DatabaseHelper.columnDuration: int.tryParse(_durationController.text) ?? 0,
        DatabaseHelper.columnNotes: _notesController.text,
        DatabaseHelper.columnMood: _moodController.text,
      };

      await dbHelper.insertReadLog(newLog);

      // Feature 1: Change status to 'reading' on first log entry
      if (currentBookStatus == 'toRead') {
        final bool? confirmChange = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('책 상태 변경'),
              content: const Text('이 책의 상태를 \'읽는 중\'으로 변경하시겠습니까?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
        if (confirmChange == true) {
          await dbHelper.updateBook({
            DatabaseHelper.columnId: widget.bookId,
            DatabaseHelper.columnStatus: 'reading',
            DatabaseHelper.columnUpdatedAt: now,
          });
        }
      }

      // Feature 2: Change status to 'finished' on last page read
      if (endPage == totalPages && totalPages > 0) {
        final bool? confirmFinish = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('책 상태 변경'),
              content: const Text('이 책을 완독으로 표시하시겠습니까?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
        if (confirmFinish == true) {
          await dbHelper.updateBook({
            DatabaseHelper.columnId: widget.bookId,
            DatabaseHelper.columnStatus: 'finished',
            DatabaseHelper.columnUpdatedAt: now,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('읽은 로그를 추가했습니다.')),
        );
        Navigator.of(context).pop(true); // true를 반환하여 목록 새로고침을 알림
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBook) {
      return Scaffold(
        appBar: AppBar(title: const Text('읽은 로그 추가')),
        body: const Center(child: const CircularProgressIndicator()),
      );
    }

    if (_bookData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('읽은 로그 추가')),
        body: const Center(child: const Text('책 정보를 불러올 수 없습니다.')),
      );
    }

    final int totalPages = _bookData![DatabaseHelper.columnTotalPages] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('읽은 로그 추가'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReadLog,
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
                controller: _readingDateController,
                decoration: const InputDecoration(
                  labelText: '독서 날짜',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '독서 날짜를 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _endPageController,
                decoration: InputDecoration(labelText: '읽은 마지막 페이지 (총 $totalPages 페이지)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '읽은 마지막 페이지를 입력해주세요.';
                  }
                  final int? endPage = int.tryParse(value);
                  if (endPage == null || endPage <= 0) {
                    return '유효한 페이지 숫자를 입력해주세요.';
                  }
                  if (endPage > totalPages) {
                    return '총 페이지($totalPages)를 초과할 수 없습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: '독서 시간 (분)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return '유효한 숫자를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _moodController,
                decoration: const InputDecoration(labelText: '기분 (선택)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
