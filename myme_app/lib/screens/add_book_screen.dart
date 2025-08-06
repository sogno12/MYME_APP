import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/reading_service.dart';
import '../services/app_service.dart';
import '../utils/date_formatter.dart';
import 'book_search_screen.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _notesController = TextEditingController();
  
  ReadingStatus _selectedStatus = ReadingStatus.toRead;
  double? _rating;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _thumbnailController.dispose();
    _totalPagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveBook() {
    if (_formKey.currentState!.validate()) {
      final book = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        thumbnailUrl: _thumbnailController.text.trim().isEmpty 
            ? null 
            : _thumbnailController.text.trim(),
        totalPages: int.parse(_totalPagesController.text),
        status: _selectedStatus,
        manualStartDate: _startDate,
        manualEndDate: _endDate,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        rating: _rating,
      );

      ReadingService().addBook(book);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveBook,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: AppService(),
          builder: (context, child) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
            // API 연결 확인 중일 때 로딩 표시
            if (AppService().isCheckingConnectivity) ...[
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('도서 검색 기능 확인 중...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]
            // 카카오 API 사용 가능한 경우에만 검색 영역 표시
            else if (AppService().isKakaoApiAvailable) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.search, size: 32),
                      const SizedBox(height: 8),
                      const Text('도서 검색으로 간편하게 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('카카오 도서 검색을 통해 도서 정보를 자동으로 가져올 수 있습니다'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (context) => const BookSearchScreen()),
                          );
                          if (result == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('도서 검색하기'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('또는 직접 입력', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              // API 사용 불가능한 경우 안내 메시지 (선택적)
              if (!AppService().isCheckingConnectivity)
                Card(
                  color: Colors.orange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 32, color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text('도서 검색 기능 사용 불가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('카카오 API 키가 설정되지 않았거나 인터넷 연결을 확인해주세요'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await AppService().refreshApiStatus();
                            // ListenableBuilder가 자동으로 UI를 갱신
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a book title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the author name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbnailController,
              decoration: const InputDecoration(
                labelText: 'Thumbnail URL (optional)',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/book-cover.jpg',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalPagesController,
              decoration: const InputDecoration(
                labelText: 'Total Pages *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the total number of pages';
                }
                final pages = int.tryParse(value);
                if (pages == null || pages <= 0) {
                  return 'Please enter a valid number of pages';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReadingStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ReadingStatus.values.map((status) {
                String label;
                switch (status) {
                  case ReadingStatus.toRead:
                    label = 'To Read';
                    break;
                  case ReadingStatus.reading:
                    label = 'Currently Reading';
                    break;
                  case ReadingStatus.completed:
                    label = 'Completed';
                    break;
                  case ReadingStatus.paused:
                    label = 'Paused';
                    break;
                  case ReadingStatus.dropped:
                    label = 'Dropped';
                    break;
                }
                return DropdownMenuItem(
                  value: status,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reading Dates (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Leave empty to auto-calculate from reading logs', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow),
                      title: const Text('Start Date'),
                      subtitle: Text(_startDate != null ? DateFormatter.format(_startDate!) : 'Not set'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_startDate != null)
                            IconButton(
                              onPressed: () => setState(() => _startDate = null),
                              icon: const Icon(Icons.clear, size: 16),
                            ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate != null && _endDate!.isBefore(picked)) {
                              _endDate = null;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.stop),
                      title: const Text('End Date'),
                      subtitle: Text(_endDate != null ? DateFormatter.format(_endDate!) : 'Not set'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              onPressed: () => setState(() => _endDate = null),
                              icon: const Icon(Icons.clear, size: 16),
                            ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rating (optional)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < (_rating?.round() ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              })..add(
                TextButton(
                  onPressed: () {
                    setState(() {
                      _rating = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Your thoughts about this book...',
              ),
              maxLines: 3,
            ),
            ],
          ),
        ),
      ),
    );
  }
}