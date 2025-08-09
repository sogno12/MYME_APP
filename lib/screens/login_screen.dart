import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/screens/home_screen.dart';
import 'package:myme_app/screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  bool _rememberMe = false;

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    // 입력된 비밀번호를 동일한 방식으로 암호화
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    // DB에서 사용자 조회
    final user = await _dbHelper.getUser(email, hashedPassword);

    if (user != null) {
      // 로그인 성공
      if (_rememberMe) {
        // '자동 로그인'이 체크되었으면 SharedPreferences에 이메일 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
      }
      // 홈 화면으로 이동 (이전 화면 스택을 모두 제거하고 홈 화면을 새로 띄움)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen(userEmail: email)),
        (Route<dynamic> route) => false,
      );
    } else {
      // 로그인 실패
      _showSnackBar('이메일 또는 비밀번호가 올바르지 않습니다.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MyMe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 48.0),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('자동 로그인'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: 비밀번호 찾기 기능 구현
                      },
                      child: const Text('비밀번호 찾기'),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('로그인', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    // 회원가입 화면으로 이동
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text('계정이 없으신가요? 회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}