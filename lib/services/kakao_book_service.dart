import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:myme_app/models/kakao_book.dart';

class KakaoBookService {
  static final String? _apiKey = dotenv.env['KAKAO_REST_API_KEY'];

  static Future<List<KakaoBook>> searchBooks(String query) async {
    if (_apiKey == null) {
      throw Exception('API key is not found in .env file');
    }

    final response = await http.get(
      Uri.parse('https://dapi.kakao.com/v3/search/book?query=$query'),
      headers: {'Authorization': 'KakaoAK $_apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> documents = data['documents'];
      return documents.map((item) => KakaoBook.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}
