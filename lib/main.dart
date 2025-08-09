import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myme_app/screens/home_screen.dart';
import 'package:myme_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // main 함수에서 비동기 작업을 수행하기 위해 필요합니다.
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱 시작 시 자동 로그인 정보를 확인하는 함수
  Future<String?> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 이메일이 있으면 그 이메일을 반환, 없으면 null 반환
    return prefs.getString('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMe',
      theme: ThemeData(
        useMaterial3: true, // Material 3 디자인 시스템 활성화
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), // 앱의 전체적인 색상 톤 설정
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      // FutureBuilder를 사용하여 비동기 작업(로그인 상태 확인) 결과에 따라 다른 화면을 보여줍니다.
      home: FutureBuilder<String?>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          // 연결 상태를 확인합니다.
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 로딩 중일 때 보여줄 위젯
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 데이터(저장된 이메일)가 있는지 확인합니다.
          if (snapshot.hasData && snapshot.data != null) {
            // 저장된 이메일이 있으면 홈 화면으로 이동
            return HomeScreen(userEmail: snapshot.data!);
          } else {
            // 저장된 이메일이 없으면 로그인 화면으로 이동
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
