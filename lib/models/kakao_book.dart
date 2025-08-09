class KakaoBook {
  final String title;
  final List<String> authors;
  final String publisher;
  final String isbn;
  final String thumbnail;
  final String contents;

  KakaoBook({
    required this.title,
    required this.authors,
    required this.publisher,
    required this.isbn,
    required this.thumbnail,
    required this.contents,
  });

  factory KakaoBook.fromJson(Map<String, dynamic> json) {
    return KakaoBook(
      title: json['title'] ?? '',
      authors: List<String>.from(json['authors'] ?? []),
      publisher: json['publisher'] ?? '',
      isbn: json['isbn'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      contents: json['contents'] ?? '',
    );
  }
}
