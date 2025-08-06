import 'package:flutter/foundation.dart';
import 'kakao_book_service.dart';

class AppService extends ChangeNotifier {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  bool _isKakaoApiAvailable = false;
  bool _isCheckingConnectivity = true;

  bool get isKakaoApiAvailable => _isKakaoApiAvailable;
  bool get isCheckingConnectivity => _isCheckingConnectivity;

  Future<void> initializeApp() async {
    _isCheckingConnectivity = true;
    notifyListeners();

    // 카카오 API 연결 상태 확인
    _isKakaoApiAvailable = await KakaoBookService.checkConnectivity();
    
    _isCheckingConnectivity = false;
    notifyListeners();
  }

  // 수동으로 API 상태 재확인
  Future<void> refreshApiStatus() async {
    _isCheckingConnectivity = true;
    notifyListeners();

    _isKakaoApiAvailable = await KakaoBookService.checkConnectivity();
    
    _isCheckingConnectivity = false;
    notifyListeners();
  }
}