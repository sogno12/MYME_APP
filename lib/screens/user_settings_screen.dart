import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';

// 시스템 설정과 동일한 기능 목록을 사용
import 'package:myme_app/screens/system_settings_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  final int userId;

  const UserSettingsScreen({super.key, required this.userId});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  Map<String, bool> _featureSwitches = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  // DB에서 현재 사용자의 설정 값을 불러오는 함수
  void _loadUserSettings() async {
    final loadedSwitches = await _dbHelper.getAllUserSettings(widget.userId);
    setState(() {
      _featureSwitches = loadedSwitches;
      _isLoading = false;
    });
  }

  // 변경된 모든 설정을 DB에 저장하는 함수
  void _saveAllUserSettings() {
    for (var entry in _featureSwitches.entries) {
      _dbHelper.setUserSetting(widget.userId, entry.key, entry.value.toString());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환경설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAllUserSettings,
            tooltip: '저장',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: availableFeatures.entries.map((entry) {
                final key = entry.key;
                final name = entry.value;
                return SwitchListTile(
                  title: Text(name),
                  subtitle: Text('$name 기능을 하단 네비게이션 바에 표시합니다.'),
                  value: _featureSwitches[key] ?? false,
                  onChanged: (bool value) {
                    setState(() {
                      _featureSwitches[key] = value;
                    });
                  },
                );
              }).toList(),
            ),
    );
  }
}
