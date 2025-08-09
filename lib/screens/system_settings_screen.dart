import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';

// 설정 가능한 기능 목록
const Map<String, String> availableFeatures = {
  'book_log': '독서기록',
  'habit_tracker': '습관 트래커',
  'todo_list': 'TODO 리스트',
  'memory_tracker': '기억 트래커',
};

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  Map<String, bool> _featureSwitches = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // DB에서 설정 값을 불러오는 함수
  void _loadSettings() async {
    Map<String, bool> loadedSwitches = {};
    for (var featureKey in availableFeatures.keys) {
      final value = await _dbHelper.getSystemSetting(featureKey);
      // 저장된 값이 'true'이면 true, 아니면 false
      loadedSwitches[featureKey] = value == 'true';
    }
    setState(() {
      _featureSwitches = loadedSwitches;
    });
  }

  // 변경된 모든 설정을 DB에 저장하는 함수
  void _saveAllSettings() {
    for (var entry in _featureSwitches.entries) {
      _dbHelper.setSystemSetting(entry.key, entry.value.toString());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시스템 환경설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAllSettings,
            tooltip: '저장',
          ),
        ],
      ),
      body: _featureSwitches.isEmpty
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