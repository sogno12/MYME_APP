import 'package:flutter/material.dart';
import 'package:myme_app/models/kakao_book.dart';
import 'package:myme_app/screens/features/confirm_book_screen.dart';
import 'package:myme_app/services/kakao_book_service.dart';

class BookSearchScreen extends StatefulWidget {
  final int userId;

  const BookSearchScreen({super.key, required this.userId});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<KakaoBook> _searchResults = [];
  bool _isLoading = false;

  void _search() async {
    if (_searchController.text.isEmpty) {
      return;
    }
    // Hide keyboard
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await KakaoBookService.searchBooks(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle error
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('책 검색에 실패했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '검색어',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final book = _searchResults[index];
                      return ListTile(
                        leading: book.thumbnail.isNotEmpty
                            ? Image.network(book.thumbnail)
                            : null,
                        title: Text(book.title),
                        subtitle: Text(book.authors.join(', ')),
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ConfirmBookScreen(
                                book: book,
                                userId: widget.userId,
                              ),
                            ),
                          );

                          if (result == true) {
                            // Pop the search screen if a book was added, and pass the result back
                            Navigator.of(context).pop(true);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
