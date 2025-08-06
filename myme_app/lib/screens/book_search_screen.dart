import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/kakao_book.dart';
import '../services/kakao_book_service.dart';
import '../services/reading_service.dart';
import '../utils/date_formatter.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<KakaoBook> _searchResults = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMorePages) {
        _loadMoreBooks();
      }
    }
  }

  Future<void> _searchBooks() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _searchResults.clear();
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final results = await KakaoBookService.searchBooks(
        _searchController.text.trim(),
        page: _currentPage,
        size: 10,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _hasMorePages = results.length == 10;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;
      final results = await KakaoBookService.searchBooks(
        _searchController.text.trim(),
        page: _currentPage,
        size: 10,
      );
      
      setState(() {
        _searchResults.addAll(results);
        _isLoading = false;
        _hasMorePages = results.length == 10;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPage--; // 실패시 페이지 번호 되돌리기
      });
    }
  }

  void _addBookFromSearch(KakaoBook kakaoBook) {
    showDialog(
      context: context,
      builder: (context) => _AddBookDialog(kakaoBook: kakaoBook),
    ).then((result) {
      if (result == true) {
        if (mounted) {
          Navigator.pop(context, true); // 검색 화면 닫고 AddBookScreen으로 true 전달
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도서 검색'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '도서명, 저자명, ISBN으로 검색',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchBooks,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('검색 중 오류가 발생했습니다'),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchBooks,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('도서를 검색해보세요', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('제목, 저자명, ISBN으로 검색할 수 있습니다'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final book = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: book.thumbnail.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      book.thumbnail,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, size: 40),
                    ),
                  )
                : const Icon(Icons.book, size: 40),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.authors.isNotEmpty)
                  Text(
                    '저자: ${book.authorsString}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (book.translators.isNotEmpty)
                  Text(
                    '번역: ${book.translatorsString}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (book.publisher.isNotEmpty)
                  Text(
                    '출판사: ${book.publisher}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                if (book.formattedPublishDate.isNotEmpty)
                  Text(
                    '출간일: ${book.formattedPublishDate}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (book.price > 0)
                  Text(
                    '가격: ${book.formattedPrice}${book.salePrice > 0 && book.salePrice != book.price ? ' (할인가: ${book.formattedSalePrice})' : ''}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (book.contents.isNotEmpty)
                  Text(
                    book.contents,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _addBookFromSearch(book),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(60, 30),
              ),
              child: const Text('추가', style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}

class _AddBookDialog extends StatefulWidget {
  final KakaoBook kakaoBook;

  const _AddBookDialog({required this.kakaoBook});

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _totalPagesController = TextEditingController();
  final _notesController = TextEditingController();
  ReadingStatus _selectedStatus = ReadingStatus.toRead;
  double? _rating;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _totalPagesController.text = widget.kakaoBook.estimatedPages.toString();
  }

  @override
  void dispose() {
    _totalPagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveBook() {
    final book = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.kakaoBook.title,
      author: widget.kakaoBook.authorsString,
      thumbnailUrl: widget.kakaoBook.thumbnail.isEmpty ? null : widget.kakaoBook.thumbnail,
      totalPages: int.tryParse(_totalPagesController.text) ?? widget.kakaoBook.estimatedPages,
      status: _selectedStatus,
      manualStartDate: _startDate,
      manualEndDate: _endDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      rating: _rating,
    );

    ReadingService().addBook(book);
    Navigator.pop(context, true); // 현재 다이얼로그 닫기
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('도서 정보 확인'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.kakaoBook.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (widget.kakaoBook.authors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('저자: ${widget.kakaoBook.authorsString}'),
              ),
            if (widget.kakaoBook.translators.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('번역가: ${widget.kakaoBook.translatorsString}'),
              ),
            if (widget.kakaoBook.publisher.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('출판사: ${widget.kakaoBook.publisher}'),
              ),
            if (widget.kakaoBook.formattedPublishDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('출간일: ${widget.kakaoBook.formattedPublishDate}'),
              ),
            if (widget.kakaoBook.price > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('가격: ${widget.kakaoBook.formattedPrice}${widget.kakaoBook.salePrice > 0 && widget.kakaoBook.salePrice != widget.kakaoBook.price ? ' (할인가: ${widget.kakaoBook.formattedSalePrice})' : ''}'),
              ),
            if (widget.kakaoBook.isbn.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('ISBN: ${widget.kakaoBook.isbn}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalPagesController,
              decoration: const InputDecoration(
                labelText: '총 페이지 수 *',
                border: OutlineInputBorder(),
                helperText: '예상 페이지 수입니다. 정확한 페이지 수를 입력해주세요.',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReadingStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: '읽기 상태',
                border: OutlineInputBorder(),
              ),
              items: ReadingStatus.values.map((status) {
                String label;
                switch (status) {
                  case ReadingStatus.toRead:
                    label = '읽을 예정';
                    break;
                  case ReadingStatus.reading:
                    label = '읽는 중';
                    break;
                  case ReadingStatus.completed:
                    label = '완독';
                    break;
                  case ReadingStatus.paused:
                    label = '중단';
                    break;
                  case ReadingStatus.dropped:
                    label = '포기';
                    break;
                }
                return DropdownMenuItem(value: status, child: Text(label));
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _saveBook,
          child: const Text('추가'),
        ),
      ],
    );
  }
}