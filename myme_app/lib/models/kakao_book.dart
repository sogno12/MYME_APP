class KakaoBook {
  final String title;
  final String contents;
  final String url;
  final String isbn;
  final String datetime;
  final List<String> authors;
  final String publisher;
  final List<String> translators;
  final int price;
  final int salePrice;
  final String thumbnail;
  final String status;

  KakaoBook({
    required this.title,
    required this.contents,
    required this.url,
    required this.isbn,
    required this.datetime,
    required this.authors,
    required this.publisher,
    required this.translators,
    required this.price,
    required this.salePrice,
    required this.thumbnail,
    required this.status,
  });

  factory KakaoBook.fromJson(Map<String, dynamic> json) {
    return KakaoBook(
      title: json['title'] ?? '',
      contents: json['contents'] ?? '',
      url: json['url'] ?? '',
      isbn: json['isbn'] ?? '',
      datetime: json['datetime'] ?? '',
      authors: List<String>.from(json['authors'] ?? []),
      publisher: json['publisher'] ?? '',
      translators: List<String>.from(json['translators'] ?? []),
      price: json['price'] ?? 0,
      salePrice: json['sale_price'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      status: json['status'] ?? '',
    );
  }

  String get authorsString => authors.join(', ');
  String get translatorsString => translators.join(', ');
  
  // 출판날짜를 YYYY/MM/DD 형식으로 포맷
  String get formattedPublishDate {
    if (datetime.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(datetime);
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime.split('T').first; // ISO 형식에서 날짜 부분만 추출
    }
  }
  
  // 가격 정보를 원화로 포맷
  String get formattedPrice {
    if (price <= 0) return '가격 정보 없음';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }
  
  String get formattedSalePrice {
    if (salePrice <= 0) return '';
    return '${salePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }
  
  // ISBN에서 페이지 수를 추출할 수 없으므로 기본값 사용
  int get estimatedPages => 300; // 기본값, 나중에 사용자가 수정 가능
}