import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_service.dart';
import '../utils/date_formatter.dart';
import 'edit_book_screen.dart';
import 'edit_session_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final ReadingService _readingService = ReadingService();
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  void _refreshBook() {
    setState(() {
      _book = _readingService.getBook(_book.id) ?? _book;
    });
  }

  void _showAddSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReadingSessionDialog(
        book: _book,
        onSessionAdded: _refreshBook,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _readingService.getSessionsForBook(_book.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBookScreen(book: _book),
                ),
              ).then((_) => _refreshBook());
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _book.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _book.thumbnailUrl!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 80,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.book, size: 40),
                              ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.book, size: 40),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _book.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${_book.author}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _book.progressPercentage / 100,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_book.currentPage}/${_book.totalPages} pages (${_book.progressPercentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (_book.displayStartDate != null || _book.displayEndDate != null) ...[
                        const SizedBox(height: 8),
                        if (_book.displayStartDate != null)
                          Text(
                            'Started: ${DateFormatter.format(_book.displayStartDate!)}${_book.manualStartDate != null ? ' (manual)' : ' (from logs)'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        if (_book.displayEndDate != null)
                          Text(
                            'Finished: ${DateFormatter.format(_book.displayEndDate!)}${_book.manualEndDate != null ? ' (manual)' : ' (from logs)'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                      if (_book.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < _book.rating!.round() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reading Sessions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddSessionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Log Reading'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No reading sessions yet'),
                        SizedBox(height: 8),
                        Text('Tap "Log Reading" to add your first session'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '${session.pagesRead}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(
                            '${session.formattedDuration} reading',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pages ${session.startPage + 1}-${session.endPage}'),
                              Text(
                                DateFormatter.format(session.readingDate),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${session.pagesPerMinute.toStringAsFixed(1)} p/m',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Icon(Icons.edit, size: 16, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSessionScreen(
                                  book: _book,
                                  session: session,
                                ),
                              ),
                            ).then((_) => _refreshBook());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AddReadingSessionDialog extends StatefulWidget {
  final Book book;
  final VoidCallback onSessionAdded;

  const AddReadingSessionDialog({
    super.key,
    required this.book,
    required this.onSessionAdded,
  });

  @override
  State<AddReadingSessionDialog> createState() => _AddReadingSessionDialogState();
}

class _AddReadingSessionDialogState extends State<AddReadingSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _endPageController = TextEditingController();
  final _notesController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');
  
  String? _mood;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final lastPage = ReadingService().getLastPageForBook(widget.book.id);
    _endPageController.text = (lastPage + 1).toString();
  }

  @override
  void dispose() {
    _endPageController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      final endPage = int.parse(_endPageController.text);
      final pagesRead = ReadingService().calculatePagesRead(widget.book.id, endPage);

      if (pagesRead <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End page must be greater than last read page')),
        );
        return;
      }

      final hours = int.tryParse(_hoursController.text) ?? 0;
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final duration = Duration(hours: hours, minutes: minutes);

      if (duration.inMinutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0 minutes')),
        );
        return;
      }

      final now = DateTime.now();
      final session = ReadingSession(
        id: now.millisecondsSinceEpoch.toString(),
        bookId: widget.book.id,
        readingDate: _selectedDate,
        createdAt: now,
        updatedAt: now,
        duration: duration,
        endPage: endPage,
        pagesRead: pagesRead,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        mood: _mood,
      );

      ReadingService().addReadingSession(session);
      widget.onSessionAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = ReadingService().getLastPageForBook(widget.book.id);

    return AlertDialog(
      title: const Text('Log Reading Session'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Last page read: $lastPage'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Reading Date'),
              subtitle: Text(DateFormatter.format(_selectedDate)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endPageController,
              decoration: const InputDecoration(
                labelText: 'End Page *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the end page';
                }
                final page = int.tryParse(value);
                if (page == null || page <= lastPage || page > widget.book.totalPages) {
                  return 'Invalid page number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final hours = int.tryParse(value);
                      if (hours == null || hours < 0 || hours > 23) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final minutes = int.tryParse(value);
                      if (minutes == null || minutes < 0 || minutes > 59) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSession,
          child: const Text('Save'),
        ),
      ],
    );
  }
}