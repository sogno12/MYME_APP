import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/kakao_book.dart';

class ConfirmBookScreen extends StatelessWidget {
  final KakaoBook book;
  final int userId;

  const ConfirmBookScreen({super.key, required this.book, required this.userId});

  Future<void> _addBook(BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    final now = DateTime.now().toIso8601String();

    final newBook = {
      DatabaseHelper.columnTitle: book.title,
      DatabaseHelper.columnAuthors: jsonEncode(book.authors),
      DatabaseHelper.columnPublisher: book.publisher,
      DatabaseHelper.columnIsbn: book.isbn,
      DatabaseHelper.columnThumbnailUrl: book.thumbnail,
      DatabaseHelper.columnStatus: 'toRead',
      DatabaseHelper.columnCreatedAt: now,
      DatabaseHelper.columnUpdatedAt: now,
      DatabaseHelper.columnOwnerId: userId,
      DatabaseHelper.columnCreatedBy: userId,
      DatabaseHelper.columnUpdatedBy: userId,
    };

    await dbHelper.insertBook(newBook);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('책이 추가되었습니다.')),
    );

    // Pop twice to go back to the book log screen
    Navigator.of(context).pop(true); // Pop ConfirmBookScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 추가 확인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.thumbnail.isNotEmpty)
              Center(
                child: Image.network(book.thumbnail, height: 200),
              ),
            const SizedBox(height: 16),
            Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('저자: ${book.authors.join(', ')}'),
            const SizedBox(height: 8),
            Text('출판사: ${book.publisher}'),
            const SizedBox(height: 8),
            Text('ISBN: ${book.isbn}'),
            const SizedBox(height: 8),
            Text('내용: ${book.contents}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addBook(context),
                child: const Text('내 서재에 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
