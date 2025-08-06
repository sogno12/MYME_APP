import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/reading_service.dart';
import '../utils/date_formatter.dart';

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
      Navigator.pop(context);
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
    );
  }
}