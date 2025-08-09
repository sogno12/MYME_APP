import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/screens/features/edit_book_screen.dart';

class FullBookDetailScreen extends StatefulWidget {
  final int bookId;

  const FullBookDetailScreen({super.key, required this.bookId});

  @override
  State<FullBookDetailScreen> createState() => _FullBookDetailScreenState();
}

class _FullBookDetailScreenState extends State<FullBookDetailScreen> {
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _bookData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  void _loadBookDetails() async {
    final data = await dbHelper.getBookById(widget.bookId);
    setState(() {
      _bookData = data;
      _isLoading = false;
    });
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('책 삭제'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('정말로 이 책을 삭제하시겠습니까?'),
                Text('관련된 모든 독서 기록도 함께 삭제됩니다.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await dbHelper.deleteBook(widget.bookId);
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBookScreen(bookId: widget.bookId),
      ),
    );
    if (result == true) {
      _loadBookDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bookData?[DatabaseHelper.columnTitle] ?? '도서 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEditScreen,
            tooltip: '수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: '삭제',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookData == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다.'))
              : _buildBookDetailsView(),
    );
  }

  Widget _buildBookDetailsView() {
    String formatDate(String? dateString) {
      if (dateString == null) return '미지정';
      try {
        final dateTime = DateTime.parse(dateString);
        return DateFormat('yyyy/MM/dd').format(dateTime);
      } catch (e) {
        return '날짜 형식 오류';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(Icons.book, size: 150, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('제목', _bookData![DatabaseHelper.columnTitle]),
          _buildDetailRow('저자', _bookData![DatabaseHelper.columnAuthors]),
          _buildDetailRow('독서 상태', _bookData![DatabaseHelper.columnStatus]),
          _buildDetailRow('총 페이지', _bookData![DatabaseHelper.columnTotalPages]?.toString()),
          _buildDetailRow('내 평점', _bookData![DatabaseHelper.columnRating]?.toString()),
          _buildDetailRow('독서 시작일', formatDate(_bookData![DatabaseHelper.columnManualStartDate])),
          _buildDetailRow('독서 완료일', formatDate(_bookData![DatabaseHelper.columnManualEndDate])),
          const Divider(height: 32),
          Text('메모', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_bookData![DatabaseHelper.columnNotes] ?? '작성된 메모가 없습니다.'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value ?? '미지정', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
