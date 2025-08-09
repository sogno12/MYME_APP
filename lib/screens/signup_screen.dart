import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for utf8

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  void _signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 입력 필드 유효성 검사
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('유효한 이메일 형식이 아닙니다.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    // 이메일 중복 확인
    final userExists = await _dbHelper.checkUserExists(email);
    if (userExists) {
      _showSnackBar('이미 사용 중인 이메일입니다.');
      return;
    }

    // 비밀번호 암호화 (SHA-256)
    final bytes = utf8.encode(password); // 비밀번호를 바이트로 변환
    final digest = sha256.convert(bytes); // SHA-256 해시 계산
    final hashedPassword = digest.toString(); // 해시 값을 문자열로 변환

    // 데이터베이스에 저장
    final row = {
      DatabaseHelper.columnEmail: email,
      DatabaseHelper.columnPassword: hashedPassword,
    };
    await _dbHelper.insertUser(row);

    _showSnackBar('회원가입이 완료되었습니다. 로그인 해주세요.', isError: false);
    // 회원가입 성공 후 로그인 화면으로 돌아가기
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '새 계정 만들기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('가입하기', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}