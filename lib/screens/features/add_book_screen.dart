import 'package:flutter/material.dart';
import 'package:myme_app/screens/features/add_manual_book_screen.dart';
import 'package:myme_app/screens/features/book_search_screen.dart';

class AddBookScreen extends StatelessWidget {
  final int userId;

  const AddBookScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 책 추가'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookSearchScreen(userId: userId),
                  ),
                );

                if (result == true) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('책 검색하여 추가'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddManualBookScreen(userId: userId),
                  ),
                );

                if (result == true) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('또는 수동으로 입력'),
            ),
          ],
        ),
      ),
    );
  }
}
