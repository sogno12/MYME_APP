import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';

class EditReadLogScreen extends StatefulWidget {
  final int readLogId;

  const EditReadLogScreen({super.key, required this.readLogId});

  @override
  State<EditReadLogScreen> createState() => _EditReadLogScreenState();
}

class _EditReadLogScreenState extends State<EditReadLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _initialData;
  Map<String, dynamic>? _bookData; // 책 정보 저장
  bool _isLoading = true; // 전체 로딩 상태

  final _readingDateController = TextEditingController();
  final _endPageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _moodController = TextEditingController();

  DateTime? _selectedReadingDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    final logData = await dbHelper.getReadLogById(widget.readLogId);
    if (logData != null) {
      final bookData = await dbHelper.getBookById(logData[DatabaseHelper.columnBookId]);
      setState(() {
        _initialData = logData;
        _bookData = bookData;
        _readingDateController.text = logData[DatabaseHelper.columnReadingDate];
        _selectedReadingDate = DateFormat('yyyy/MM/dd').parse(logData[DatabaseHelper.columnReadingDate]);
        _endPageController.text = logData[DatabaseHelper.columnEndPage]?.toString() ?? '';
        _durationController.text = logData[DatabaseHelper.columnDuration]?.toString() ?? '';
        _notesController.text = logData[DatabaseHelper.columnNotes] ?? '';
        _moodController.text = logData[DatabaseHelper.columnMood] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
    if (picked != null && picked != _selectedReadingDate) {
      setState(() {
        _selectedReadingDate = picked;
        _readingDateController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  Future<void> _showSaveConfirmationDialog() async {
    if (_formKey.currentState!.validate()) {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('로그 수정'),
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
                  _saveReadLogChanges();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _saveReadLogChanges() async {
    if (_initialData == null || _bookData == null) return; // 데이터 로딩 실패 시 저장 안 함

    final now = DateTime.now().toIso8601String();
    final int endPage = int.tryParse(_endPageController.text) ?? 0;
    final int totalPages = _bookData![DatabaseHelper.columnTotalPages] ?? 0;

    final updatedLog = {
      DatabaseHelper.columnId: widget.readLogId,
      DatabaseHelper.columnUpdatedAt: now,
      DatabaseHelper.columnReadingDate: DateFormat('yyyy/MM/dd').format(_selectedReadingDate!), // 날짜 형식 통일
      DatabaseHelper.columnEndPage: endPage,
      DatabaseHelper.columnDuration: int.tryParse(_durationController.text) ?? 0,
      DatabaseHelper.columnNotes: _notesController.text,
      DatabaseHelper.columnMood: _moodController.text,
      // 변경되지 않는 값들
      DatabaseHelper.columnCreatedAt: _initialData![DatabaseHelper.columnCreatedAt],
      DatabaseHelper.columnOwnerId: _initialData![DatabaseHelper.columnOwnerId],
      DatabaseHelper.columnCreatedBy: _initialData![DatabaseHelper.columnCreatedBy],
      DatabaseHelper.columnUpdatedBy: _initialData![DatabaseHelper.columnOwnerId], // 수정자는 현재 사용자로
      DatabaseHelper.columnBookId: _initialData![DatabaseHelper.columnBookId],
    };

    await dbHelper.updateReadLog(updatedLog);

    // Feature: Change status to 'finished' on last page read
    if (endPage == totalPages && totalPages > 0) {
      final bool? confirmFinish = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('책 상태 변경'),
            content: const Text('이 책을 \'완독\'으로 표시하시겠습니까?'),
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
          DatabaseHelper.columnId: _initialData![DatabaseHelper.columnBookId],
          DatabaseHelper.columnStatus: 'finished',
          DatabaseHelper.columnUpdatedAt: now,
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('읽은 로그가 수정되었습니다.')),
      );
      Navigator.of(context).pop(true); // true 반환하여 목록 새로고침
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그 삭제'),
          content: const Text('정말로 이 독서 기록을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final int bookId = _initialData![DatabaseHelper.columnBookId];
                await dbHelper.deleteReadLog(widget.readLogId);
                if (mounted) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(true); // 화면 닫고 목록 새로고침
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('읽은 로그 수정')),
        body: const Center(child: const CircularProgressIndicator()),
      );
    }

    if (_initialData == null || _bookData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('읽은 로그 수정')),
        body: const Center(child: const Text('로그 정보를 불러올 수 없습니다.')),
      );
    }

    final int totalPages = _bookData![DatabaseHelper.columnTotalPages] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('읽은 로그 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveConfirmationDialog,
            tooltip: '저장',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: '삭제',
          ),
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
