import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_service.dart';
import '../utils/date_formatter.dart';

class EditSessionScreen extends StatefulWidget {
  final Book book;
  final ReadingSession session;

  const EditSessionScreen({
    super.key,
    required this.book,
    required this.session,
  });

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _endPageController;
  late TextEditingController _notesController;
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  
  late DateTime _selectedDate;
  String? _mood;

  @override
  void initState() {
    super.initState();
    _endPageController = TextEditingController(text: widget.session.endPage.toString());
    _notesController = TextEditingController(text: widget.session.notes ?? '');
    _hoursController = TextEditingController(text: widget.session.duration.inHours.toString());
    _minutesController = TextEditingController(text: (widget.session.duration.inMinutes % 60).toString());
    _selectedDate = widget.session.readingDate;
    _mood = widget.session.mood;
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
      final startPage = endPage - widget.session.pagesRead;

      if (startPage < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid page range')),
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

      final updatedSession = widget.session.copyWith(
        readingDate: _selectedDate,
        duration: duration,
        endPage: endPage,
        pagesRead: widget.session.pagesRead, // Keep original pages read count
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        mood: _mood,
      );

      ReadingService().updateReadingSession(updatedSession);
      Navigator.pop(context);
    }
  }

  void _deleteSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading Session'),
        content: const Text('Are you sure you want to delete this reading session? This will update your reading progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ReadingService().deleteReadingSession(widget.session.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reading Session'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _deleteSession,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
          TextButton(
            onPressed: _saveSession,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'by ${widget.book.author}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text('Original: Pages ${widget.session.startPage + 1}-${widget.session.endPage}'),
                    Text('Duration: ${widget.session.formattedDuration}'),
                    Text('Pages read: ${widget.session.pagesRead}'),
                    const SizedBox(height: 8),
                    Text(
                      'Reading date: ${DateFormatter.format(widget.session.readingDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    Text(
                      'Log created: ${DateFormatter.format(widget.session.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (widget.session.updatedAt != widget.session.createdAt)
                      Text(
                        'Last updated: ${DateFormatter.format(widget.session.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
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
                helperText: 'Changing this will recalculate your reading progress',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the end page';
                }
                final page = int.tryParse(value);
                if (page == null || page <= 0 || page > widget.book.totalPages) {
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Warning: Editing or deleting this session will recalculate your book progress and may affect start/end dates.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}