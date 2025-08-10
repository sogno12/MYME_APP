import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/screens/features/add_book_screen.dart';
import 'package:myme_app/screens/features/book_detail_screen.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:myme_app/screens/features/edit_book_screen.dart';

class BookLogScreen extends StatefulWidget {
  final int userId;
  const BookLogScreen({super.key, required this.userId});

  @override
  State<BookLogScreen> createState() => _BookLogScreenState();
}

class _BookLogScreenState extends State<BookLogScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sortBy = 'created_at'; // Default sort by creation date
  String _sortOrder = 'DESC'; // Default sort order descending
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _refreshBookList();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _refreshBookList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshBookList() async {
    setState(() {
      _isLoading = true;
    });
    final data = await dbHelper.getBooks(
      widget.userId,
      searchQuery: _searchQuery,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      filterStatus: _filterStatus,
    );
    setState(() {
      _books = data;
      _isLoading = false;
    });
  }

  void _navigateToAddBook() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBookScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      _refreshBookList();
    }
  }

  void _navigateToDetail(int bookId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(bookId: bookId),
      ),
    );
    _refreshBookList();
  }

  void _showFilterAndSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '정렬 및 필터',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16.0),
                  Text('정렬 기준', style: Theme.of(context).textTheme.titleMedium),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _sortBy,
                    onChanged: (String? newValue) {
                      setModalState(() {
                        _sortBy = newValue;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('생성일')),
                      DropdownMenuItem(value: 'title', child: Text('제목')),
                      DropdownMenuItem(value: 'manual_start_date', child: Text('읽기 시작일')),
                      DropdownMenuItem(value: 'status', child: Text('상태')),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text('정렬 순서', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('오름차순'),
                          value: 'ASC',
                          groupValue: _sortOrder,
                          onChanged: (String? value) {
                            setModalState(() {
                              _sortOrder = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('내림차순'),
                          value: 'DESC',
                          groupValue: _sortOrder,
                          onChanged: (String? value) {
                            setModalState(() {
                              _sortOrder = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text('상태 필터', style: Theme.of(context).textTheme.titleMedium),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _filterStatus,
                    hint: const Text('모든 상태'),
                    onChanged: (String? newValue) {
                      setModalState(() {
                        _filterStatus = newValue;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: null, child: Text('모든 상태')),
                      DropdownMenuItem(value: 'toRead', child: Text('읽고 싶은 책')),
                      DropdownMenuItem(value: 'reading', child: Text('읽는 중')),
                      DropdownMenuItem(value: 'finished', child: Text('읽음')),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _searchController.clear();
                            _sortBy = 'created_at';
                            _sortOrder = 'DESC';
                            _filterStatus = null;
                          });
                          Navigator.pop(context);
                          _refreshBookList();
                        },
                        child: const Text('초기화'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _refreshBookList();
                        },
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _isFilterActive {
    return _searchController.text.isNotEmpty ||
        _sortBy != 'created_at' ||
        _sortOrder != 'DESC' ||
        _filterStatus != null;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _sortBy = 'created_at';
      _sortOrder = 'DESC';
      _filterStatus = null;
    });
    _refreshBookList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '제목 또는 저자 검색',
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
        actions: [
          if (_isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearAllFilters,
              tooltip: '필터 초기화',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterAndSortOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBookList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBook,
        tooltip: '새 책 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookList() {
    if (_books.isEmpty) {
      return const Center(
        child: Text(
          '아직 등록된 책이 없습니다.\n아래 버튼을 눌러 새 책을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        final bookId = book[DatabaseHelper.columnId];
        final String title = book[DatabaseHelper.columnTitle] ?? '제목 없음';
        
        String formattedAuthors;
        final String authorsData = book[DatabaseHelper.columnAuthors] ?? '저자 정보 없음';
        try {
          final List<dynamic> authorsList = jsonDecode(authorsData);
          formattedAuthors = authorsList.join(', ');
        } catch (e) {
          formattedAuthors = authorsData;
        }

        final String? startDate = book[DatabaseHelper.columnManualStartDate];
        final String? endDate = book[DatabaseHelper.columnManualEndDate];

        String dateInfo = '';
        if (startDate != null && startDate.isNotEmpty) {
          dateInfo += '시작: ${DateFormat('yyyy/MM/dd').format(DateTime.parse(startDate))}';
        }
        if (endDate != null && endDate.isNotEmpty) {
          if (dateInfo.isNotEmpty) dateInfo += ' | ';
          dateInfo += '종료: ${DateFormat('yyyy/MM/dd').format(DateTime.parse(endDate))}';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: InkWell(
            onTap: () => _navigateToDetail(bookId),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(formattedAuthors, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        if (dateInfo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(dateInfo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditBookScreen(bookId: bookId),
                        ),
                      );
                      if (result == true) {
                        _refreshBookList();
                      }
                    },
                    tooltip: '수정',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('도서 삭제'),
                            content: const Text('이 도서와 관련된 모든 읽은 로그도 삭제됩니다. 정말 삭제하시겠습니까?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('삭제'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        await dbHelper.deleteBook(bookId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('도서가 삭제되었습니다.')),
                        );
                        _refreshBookList();
                      }
                    },
                    tooltip: '삭제',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}