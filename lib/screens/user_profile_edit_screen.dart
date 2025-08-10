import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserProfileEditScreen extends StatefulWidget {
  final int userId;

  const UserProfileEditScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  late TextEditingController _nicknameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmNewPasswordController;

  String _userEmail = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await dbHelper.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        _userData = user;
        _userEmail = user[DatabaseHelper.columnEmail];
        _nicknameController = TextEditingController(text: user[DatabaseHelper.columnNickname]);
        _currentPasswordController = TextEditingController();
        _newPasswordController = TextEditingController();
        _confirmNewPasswordController = TextEditingController();
      });
    } else {
      // Handle error: user not found
      _showSnackBar('사용자 정보를 불러올 수 없습니다.', isError: true);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String newNickname = _nicknameController.text.trim();
      final String currentPassword = _currentPasswordController.text;
      final String newPassword = _newPasswordController.text;

      // Validate current password if new password fields are filled
      if (newPassword.isNotEmpty) {
        if (currentPassword.isEmpty) {
          _showSnackBar('비밀번호 변경을 위해 현재 비밀번호를 입력해주세요.', isError: true);
          return;
        }
        final bytes = utf8.encode(currentPassword);
        final hashedPassword = sha256.convert(bytes).toString();
        if (hashedPassword != _userData![DatabaseHelper.columnPassword]) {
          _showSnackBar('현재 비밀번호가 일치하지 않습니다.', isError: true);
          return;
        }
      }

      // Prepare data for update
      Map<String, dynamic> updatedData = {
        DatabaseHelper.columnId: widget.userId,
        DatabaseHelper.columnNickname: newNickname,
        DatabaseHelper.columnUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseHelper.columnUpdatedBy: widget.userId,
      };

      if (newPassword.isNotEmpty) {
        final bytes = utf8.encode(newPassword);
        updatedData[DatabaseHelper.columnPassword] = sha256.convert(bytes).toString();
      }

      await dbHelper.updateUser(updatedData);
      _showSnackBar('프로필이 성공적으로 업데이트되었습니다.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정'),
        actions: [
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: const Text('이메일'),
                      subtitle: Text(_userEmail),
                      leading: const Icon(Icons.email),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32.0),
                    const Text(
                      '비밀번호 변경 (선택 사항)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '현재 비밀번호',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 4) {
                            return '비밀번호는 4자 이상이어야 합니다.';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _confirmNewPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호 확인',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                          return '새 비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('프로필 저장', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
