import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/screens/login_screen.dart';
import 'package:myme_app/screens/system_settings_screen.dart';
import 'package:myme_app/screens/user_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 피처 스크린 임포트
import 'package:myme_app/screens/features/book_log_screen.dart';
import 'package:myme_app/screens/features/habit_tracker_screen.dart';
import 'package:myme_app/screens/features/todo_list_screen.dart';
import 'package:myme_app/screens/features/memory_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _userData;

  int _selectedIndex = 0;
  List<Widget> _featurePages = [];
  List<BottomNavigationBarItem> _navBarItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFeatures();
  }

  Future<void> _loadUserDataAndFeatures() async {
    await _loadUserData();
    await _loadEnabledFeatures();
  }

  Future<void> _loadUserData() async {
    final data = await dbHelper.getUserByEmail(widget.userEmail);
    setState(() {
      _userData = data;
    });
  }

  // 활성화된 기능 목록을 불러와 네비게이션 바와 페이지를 구성하는 함수
  Future<void> _loadEnabledFeatures() async {
    if (_userData == null) return; // 사용자 데이터가 없으면 실행하지 않음
    final userId = _userData![DatabaseHelper.columnId];

    final List<Widget> pages = [
      _buildWelcomePage(),
    ];
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: '홈',
      ),
    ];

    const featureMap = {
      'book_log': {
        'widget': BookLogScreen(),
        'icon': Icons.book_outlined,
        'activeIcon': Icons.book,
        'label': '독서기록'
      },
      'habit_tracker': {
        'widget': HabitTrackerScreen(),
        'icon': Icons.check_circle_outline,
        'activeIcon': Icons.check_circle,
        'label': '습관'
      },
      'todo_list': {
        'widget': TodoListScreen(),
        'icon': Icons.list_alt_outlined,
        'activeIcon': Icons.list_alt,
        'label': 'TODO'
      },
      'memory_tracker': {
        'widget': MemoryTrackerScreen(),
        'icon': Icons.memory_outlined,
        'activeIcon': Icons.memory,
        'label': '기억'
      },
    };

    for (var entry in featureMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // 시스템 설정과 사용자 설정을 모두 확인
      final systemEnabled = await dbHelper.getSystemSetting(key);
      final userEnabled = await dbHelper.getUserSetting(userId, key);

      // 두 설정이 모두 'true'일 때만 기능을 활성화
      if (systemEnabled == 'true' && userEnabled == 'true') {
        pages.add(value['widget'] as Widget);
        items.add(BottomNavigationBarItem(
          icon: Icon(value['icon'] as IconData),
          activeIcon: Icon(value['activeIcon'] as IconData),
          label: value['label'] as String,
        ));
      }
    }

    setState(() {
      _featurePages = pages;
      _navBarItems = items;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildWelcomePage() {
    final nickname = _userData?[DatabaseHelper.columnNickname] ?? '사용자';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$nickname 님, 환영합니다.', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _userData?[DatabaseHelper.columnNickname] ?? '사용자';
    final email = _userData?[DatabaseHelper.columnEmail] ?? widget.userEmail;
    final avatarLetter = (nickname.isNotEmpty) ? nickname[0].toUpperCase() : '?';
    final bool isAdmin = _userData != null && _userData![DatabaseHelper.columnIsAdmin] == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyMe'),
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: CircleAvatar(
                child: Text(avatarLetter),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: '로그아웃',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    accountEmail: Text(email),
                    currentAccountPicture: CircleAvatar(
                      child: Text(avatarLetter, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('환경설정'),
              onTap: () async {
                Navigator.pop(context);
                if (_userData != null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => UserSettingsScreen(userId: _userData![DatabaseHelper.columnId])),
                  );
                  _loadEnabledFeatures(); // 설정 변경 후 네비게이션 바 새로고침
                }
              },
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('시스템 환경설정'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
                  );
                  _loadEnabledFeatures();
                },
              ),
          ],
        ),
      ),
      body: _featurePages.isNotEmpty ? _featurePages[_selectedIndex] : Center(child: _buildWelcomePage()),
      bottomNavigationBar: _navBarItems.length > 1
          ? BottomNavigationBar(
              items: _navBarItems,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            )
          : null,
    );
  }
}