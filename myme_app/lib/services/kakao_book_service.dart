import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/kakao_book.dart';

class KakaoBookService {
  static const String _baseUrl = 'https://dapi.kakao.com/v3/search/book';
  static String get _apiKey => dotenv.env['KAKAO_REST_API_KEY'] ?? '';
  
  // API 키가 있는지 확인
  static bool get hasApiKey => _apiKey.isNotEmpty;
  
  // API 연결 상태 확인 (간단한 테스트 검색)
  static Future<bool> checkConnectivity() async {
    if (!hasApiKey) return false;
    
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query': 'test',
        'page': '1',
        'size': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'KakaoAK $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<KakaoBook>> searchBooks(String query, {int page = 1, int size = 10}) async {
    if (_apiKey.isEmpty) {
      throw Exception('카카오 API 키가 설정되지 않았습니다. .env 파일에 KAKAO_REST_API_KEY를 설정해주세요.');
    }
    
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query': query,
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'accuracy',
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'KakaoAK $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> documents = data['documents'] ?? [];
        
        return documents.map((json) => KakaoBook.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}