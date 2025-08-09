import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/screens/features/full_book_detail_screen.dart';
import 'package:myme_app/screens/features/add_read_log_screen.dart';
import 'package:myme_app/screens/features/edit_read_log_screen.dart';
import 'package:myme_app/utils/reading_status_utils.dart'; // 한국어 매핑 유틸 임포트

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _bookData;
  List<Map<String, dynamic>> _readLogs = [];
  bool _isLoading = true;

  String? _sortByLog = 'reading_date'; // Default sort by reading date
  String _sortOrderLog = 'DESC'; // Default sort order descending

  @override
  void initState() {
    super.initState();
    _loadBookAndLogs();
  }

  void _loadBookAndLogs() async {
    setState(() {
      _isLoading = true;
    });
    final book = await dbHelper.getBookById(widget.bookId);
    _bookData = book; // Ensure _bookData is set before calculating previousEndPage

    // 모든 로그를 독서일 기준으로 오름차순으로 가져와서 startPage를 계산합니다.
    List<Map<String, dynamic>> chronologicalLogs = List.from(await dbHelper.getReadLogsForBook(
      widget.bookId,
      sortBy: 'reading_date',
      sortOrder: 'ASC',
    ));

    // 각 로그의 시작 페이지를 계산합니다.
    int previousEndPage = 0; // 책의 현재 페이지를 시작점으로 사용
    List<Map<String, dynamic>> logsWithCalculatedStartPage = [];
    for (var log in chronologicalLogs) {
      Map<String, dynamic> mutableLog = Map.from(log); // Create a mutable copy
      mutableLog['calculated_start_page'] = previousEndPage + 1;
      previousEndPage = mutableLog[DatabaseHelper.columnEndPage] ?? previousEndPage;
      logsWithCalculatedStartPage.add(mutableLog);
    }

    // 사용자의 정렬 기준에 따라 로그를 정렬합니다.
    List<Map<String, dynamic>> sortedLogs = List.from(logsWithCalculatedStartPage);
    if (_sortByLog != null && _sortByLog!.isNotEmpty) {
      sortedLogs.sort((a, b) {
        dynamic aValue;
        dynamic bValue;

        switch (_sortByLog) {
          case 'reading_date':
            aValue = DateFormat('yyyy/MM/dd').parse(a[DatabaseHelper.columnReadingDate]);
            bValue = DateFormat('yyyy/MM/dd').parse(b[DatabaseHelper.columnReadingDate]);
            break;
          case 'end_page':
            aValue = a[DatabaseHelper.columnEndPage] ?? 0;
            bValue = b[DatabaseHelper.columnEndPage] ?? 0;
            break;
          case 'duration':
            aValue = a[DatabaseHelper.columnDuration] ?? 0;
            bValue = b[DatabaseHelper.columnDuration] ?? 0;
            break;
          default:
            aValue = DateTime.parse(a[DatabaseHelper.columnReadingDate]);
            bValue = DateTime.parse(b[DatabaseHelper.columnReadingDate]);
            break;
        }

        int compareResult = Comparable.compare(aValue, bValue);
        return _sortOrderLog == 'ASC' ? compareResult : -compareResult;
      });
    }

    setState(() {
      _readLogs = sortedLogs;
      _isLoading = false;
    });
  }

  void _navigateToAddReadLog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddReadLogScreen(bookId: widget.bookId), // currentBookEndPage 제거
      ),
    );

    if (result == true) {
      _loadBookAndLogs(); // 로그 추가 후 목록 새로고침
    }
  }

  void _navigateToFullDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullBookDetailScreen(bookId: widget.bookId),
      ),
    );
    // 전체 상세 화면에서 수정이 있었을 수 있으므로 데이터 새로고침
    _loadBookAndLogs();
  }

  void _navigateToEditReadLog(int readLogId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditReadLogScreen(readLogId: readLogId),
      ),
    );
    if (result == true) {
      _loadBookAndLogs(); // 로그 수정/삭제 후 목록 새로고침
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bookData?[DatabaseHelper.columnTitle] ?? '도서 정보'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookData == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다.'))
              : Column(
                  children: [
                    // 상단 고정된 책 간략 정보
                    _buildBookSummary(),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _sortByLog,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _sortByLog = newValue;
                                });
                                _loadBookAndLogs();
                              },
                              items: const [
                                DropdownMenuItem(value: 'reading_date', child: Text('독서일')),
                                DropdownMenuItem(value: 'end_page', child: Text('종료 페이지')),
                                DropdownMenuItem(value: 'duration', child: Text('독서 시간')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          IconButton(
                            icon: Icon(
                              _sortOrderLog == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                            ),
                            onPressed: () {
                              setState(() {
                                _sortOrderLog = (_sortOrderLog == 'ASC') ? 'DESC' : 'ASC';
                              });
                              _loadBookAndLogs();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // 하단 스크롤 가능한 읽은 로그 목록
                    Expanded(
                      child: _buildReadLogList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddReadLog,
        tooltip: '읽은 로그 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookSummary() {
    final String? thumbnailUrl = _bookData?[DatabaseHelper.columnThumbnailUrl];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일 이미지
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.book, size: 50, color: Colors.grey[400]),
                    ),
                  )
                : Icon(Icons.book, size: 50, color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          // 책 정보 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bookData![DatabaseHelper.columnAuthors] ?? '저자 정보 없음',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '상태: ${getReadingStatusKorean(_bookData![DatabaseHelper.columnStatus] ?? '미지정')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '총 페이지: ${_bookData![DatabaseHelper.columnTotalPages]?.toString() ?? '미지정'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToFullDetail,
                    child: const Text('상세히 보기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadLogList() {
    if (_readLogs.isEmpty) {
      return const Center(
        child: Text(
          '아직 읽은 기록이 없습니다.\n아래 버튼을 눌러 기록을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _readLogs.length,
      itemBuilder: (context, index) {
        final log = _readLogs[index];
        final int endPage = log[DatabaseHelper.columnEndPage] ?? 0;
        final int calculatedStartPage = log['calculated_start_page'] ?? 1; // 계산된 시작 페이지 사용

        final String moodText = log[DatabaseHelper.columnMood] != null && log[DatabaseHelper.columnMood].isNotEmpty
            ? '기분: ${log[DatabaseHelper.columnMood]}'
            : '';
        final String durationText = log[DatabaseHelper.columnDuration] != null
            ? '${log[DatabaseHelper.columnDuration]}분'
            : '';
        
        String subtitleText = '';
        if (durationText.isNotEmpty && moodText.isNotEmpty) {
          subtitleText = '$durationText, $moodText';
        } else if (durationText.isNotEmpty) {
          subtitleText = durationText;
        } else if (moodText.isNotEmpty) {
          subtitleText = moodText;
        }

        final readLogId = log[DatabaseHelper.columnId];

        return ListTile(
          title: Text('${log[DatabaseHelper.columnReadingDate]} - $calculatedStartPage ~ $endPage 페이지'),
          subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
          onTap: () => _navigateToEditReadLog(readLogId),
        );
      },
    );
  }
}