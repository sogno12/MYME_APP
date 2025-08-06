import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/book.dart';
import 'services/reading_service.dart';
import 'services/app_service.dart';
import 'utils/date_formatter.dart';
import 'screens/add_book_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/edit_book_screen.dart';
import 'screens/edit_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // 앱 서비스 초기화
  await AppService().initializeApp();
  
  runApp(const MyMeApp());
}

class MyMeApp extends StatelessWidget {
  const MyMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMe - Scheduler & Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SchedulerScreen(),
    const HabitTrackerScreen(),
    const ReadingLogScreen(),
    const DiaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Reading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Diary',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 64),
            SizedBox(height: 16),
            Text('Welcome to MyMe!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Your daily overview will appear here'),
          ],
        ),
      ),
    );
  }
}

class SchedulerScreen extends StatelessWidget {
  const SchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64),
            SizedBox(height: 16),
            Text('Schedule & Calendar', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Your events and appointments'),
          ],
        ),
      ),
    );
  }
}

class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64),
            SizedBox(height: 16),
            Text('Habit Tracker', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Track your daily habits and streaks'),
          ],
        ),
      ),
    );
  }
}

class ReadingLogScreen extends StatefulWidget {
  const ReadingLogScreen({super.key});

  @override
  State<ReadingLogScreen> createState() => _ReadingLogScreenState();
}

enum BookSortOption {
  mostRecent,
  oldest,
  highestRating,
  lowestRating,
}

class _ReadingLogScreenState extends State<ReadingLogScreen> {
  final ReadingService _readingService = ReadingService();
  BookSortOption _sortOption = BookSortOption.mostRecent;
  Set<ReadingStatus> _statusFilters = ReadingStatus.values.toSet();

  List<Book> _getSortedBooks() {
    final books = List<Book>.from(_readingService.books)
        .where((book) => _statusFilters.contains(book.status))
        .toList();
    
    switch (_sortOption) {
      case BookSortOption.mostRecent:
        books.sort((a, b) {
          final dateA = a.displayEndDate ?? a.displayStartDate ?? DateTime(1900);
          final dateB = b.displayEndDate ?? b.displayStartDate ?? DateTime(1900);
          return dateB.compareTo(dateA);
        });
        break;
      case BookSortOption.oldest:
        books.sort((a, b) {
          final dateA = a.displayStartDate ?? a.displayEndDate ?? DateTime.now();
          final dateB = b.displayStartDate ?? b.displayEndDate ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        break;
      case BookSortOption.highestRating:
        books.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case BookSortOption.lowestRating:
        books.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingA.compareTo(ratingB);
        });
        break;
    }
    
    return books;
  }

  String _getReadingPeriodText(Book book) {
    if (book.displayStartDate != null && book.displayEndDate != null) {
      return '${DateFormatter.format(book.displayStartDate!)} - ${DateFormatter.format(book.displayEndDate!)}';
    } else if (book.displayStartDate != null) {
      return 'Started: ${DateFormatter.format(book.displayStartDate!)}';
    } else if (book.displayEndDate != null) {
      return 'Finished: ${DateFormatter.format(book.displayEndDate!)}';
    }
    return '';
  }

  String _getFilterStatusText() {
    final statusLabels = <String>[];
    for (final status in _statusFilters) {
      switch (status) {
        case ReadingStatus.toRead:
          statusLabels.add('To Read');
          break;
        case ReadingStatus.reading:
          statusLabels.add('Reading');
          break;
        case ReadingStatus.completed:
          statusLabels.add('Completed');
          break;
        case ReadingStatus.paused:
          statusLabels.add('Paused');
          break;
        case ReadingStatus.dropped:
          statusLabels.add('Dropped');
          break;
      }
    }
    return statusLabels.join(', ');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Reading Status'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _statusFilters = ReadingStatus.values.toSet();
                        });
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _statusFilters.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                ...ReadingStatus.values.map((status) {
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
                  
                  return CheckboxListTile(
                    title: Text(label),
                    value: _statusFilters.contains(status),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _statusFilters.add(status);
                        } else {
                          _statusFilters.remove(status);
                        }
                      });
                    },
                  );
                }).toList(),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Filters are already updated in the dialog
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _getSortedBooks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Log'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _statusFilters.length < ReadingStatus.values.length 
                  ? Colors.orange 
                  : null,
            ),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<BookSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: BookSortOption.mostRecent,
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: BookSortOption.oldest,
                child: Text('Oldest'),
              ),
              const PopupMenuItem(
                value: BookSortOption.highestRating,
                child: Text('Highest Rating'),
              ),
              const PopupMenuItem(
                value: BookSortOption.lowestRating,
                child: Text('Lowest Rating'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusFilters.length < ReadingStatus.values.length)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${_getFilterStatusText()}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _statusFilters = ReadingStatus.values.toSet();
                      });
                    },
                    child: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: books.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _readingService.books.isEmpty 
                              ? 'No books added yet'
                              : 'No books match your filters',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _readingService.books.isEmpty 
                              ? 'Tap + to add your first book'
                              : 'Try adjusting your filters',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: book.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              book.thumbnailUrl!,
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.book, size: 40),
                            ),
                          )
                        : const Icon(Icons.book, size: 40),
                    title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.author, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: book.progressPercentage / 100,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${book.currentPage}/${book.totalPages} pages (${book.progressPercentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (book.displayStartDate != null || book.displayEndDate != null)
                          Text(
                            _getReadingPeriodText(book),
                            style: const TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        if (book.rating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < book.rating!.round() ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                '${book.rating!.toStringAsFixed(1)}/5',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: _StatusChip(status: book.status),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(book: book),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBookScreen(),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReadingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    
    switch (status) {
      case ReadingStatus.toRead:
        color = Colors.grey;
        text = 'To Read';
        break;
      case ReadingStatus.reading:
        color = Colors.blue;
        text = 'Reading';
        break;
      case ReadingStatus.completed:
        color = Colors.green;
        text = 'Done';
        break;
      case ReadingStatus.paused:
        color = Colors.orange;
        text = 'Paused';
        break;
      case ReadingStatus.dropped:
        color = Colors.red;
        text = 'Dropped';
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }
}

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 64),
            SizedBox(height: 16),
            Text('Experience Diary', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Write about your daily experiences'),
          ],
        ),
      ),
    );
  }
}
