import 'dart:io';
import 'package:myme_app/screens/system_settings_screen.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final _databaseName = "MyMe.db";
  // isAdmin 컬럼 추가를 위해 버전을 6으로 올립니다.
  static final _databaseVersion = 6;

  // 테이블 이름
  static final usersTable = 'users';
  static final systemSettingsTable = 'system_settings';
  static final userSettingsTable = 'user_settings';

  // 공통 컬럼
  static final columnId = '_id';
  static final columnSettingKey = 'key';
  static final columnSettingValue = 'value';

  // users 테이블 컬럼
  static final columnEmail = 'email';
  static final columnPassword = 'password';
  static final columnName = 'name';
  static final columnNickname = 'nickname';
  static final columnIsAdmin = 'isAdmin'; // isAdmin 컬럼 추가

  // user_settings 테이블 컬럼
  static final columnUserId = 'user_id';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    // users 테이블 생성 (isAdmin 컬럼 추가)
    await db.execute('''
          CREATE TABLE $usersTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnEmail TEXT NOT NULL UNIQUE,
            $columnPassword TEXT NOT NULL,
            $columnName TEXT,
            $columnNickname TEXT,
            $columnIsAdmin INTEGER NOT NULL DEFAULT 0
          )
          ''');
    
    // system_settings 테이블 생성
    await db.execute('''
          CREATE TABLE $systemSettingsTable (
            $columnSettingKey TEXT PRIMARY KEY,
            $columnSettingValue TEXT NOT NULL
          )
          ''');

    // user_settings 테이블 생성
    await db.execute('''
          CREATE TABLE $userSettingsTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUserId INTEGER NOT NULL,
            $columnSettingKey TEXT NOT NULL,
            $columnSettingValue TEXT NOT NULL,
            FOREIGN KEY ($columnUserId) REFERENCES $usersTable ($columnId) ON DELETE CASCADE,
            UNIQUE ($columnUserId, $columnSettingKey)
          )
          ''');

    await _insertDefaultData(db);
  }

  // 기본 데이터 추가 (sogno 계정에 isAdmin 플래그 설정)
  Future<void> _insertDefaultData(Database db) async {
    // 1. 기본 시스템 설정 추가
    for (var featureKey in availableFeatures.keys) {
      await db.insert(systemSettingsTable, {
        columnSettingKey: featureKey,
        columnSettingValue: 'true',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. 기본 관리자 계정(sogno) 생성 (isAdmin: 1)
    final password = '1234';
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    final sognoUserId = await db.insert(usersTable, {
      columnEmail: 'sogno',
      columnPassword: hashedPassword,
      columnNickname: 'sogno',
      columnIsAdmin: 1 // 관리자 플래그를 true(1)로 설정
    });

    // 3. 생성된 관리자 계정의 사용자 설정 추가
    final systemSettings = await db.query(systemSettingsTable);
    for (var setting in systemSettings) {
      await db.insert(userSettingsTable, {
        columnUserId: sognoUserId,
        columnSettingKey: setting[columnSettingKey],
        columnSettingValue: setting[columnSettingValue],
      });
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 기존 테이블들을 삭제하고 새로 생성 (데이터는 유지되지 않음)
    await db.execute('DROP TABLE IF EXISTS $usersTable');
    await db.execute('DROP TABLE IF EXISTS $systemSettingsTable');
    await db.execute('DROP TABLE IF EXISTS $userSettingsTable');
    await _onCreate(db, newVersion);
  }

  // --- User 관련 함수 ---
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    // isAdmin은 테이블에서 DEFAULT 0으로 처리되므로 별도 지정 필요 없음
    final userId = await db.insert(usersTable, row);
    await createUserSettings(userId);
    return userId;
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(usersTable, 
        where: '$columnEmail = ? AND $columnPassword = ?', 
        whereArgs: [email, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(usersTable,
        where: '$columnEmail = ?',
        whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<bool> checkUserExists(String email) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(usersTable,
        where: '$columnEmail = ?',
        whereArgs: [email]);
    return res.isNotEmpty;
  }

  // --- System Settings 관련 함수 ---
  Future<void> setSystemSetting(String key, String value) async {
    Database db = await instance.database;
    await db.insert(
      systemSettingsTable,
      {columnSettingKey: key, columnSettingValue: value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSystemSetting(String key) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      systemSettingsTable,
      where: '$columnSettingKey = ?',
      whereArgs: [key],
    );
    return res.isNotEmpty ? res.first[columnSettingValue] : null;
  }

  // --- User Settings 관련 함수 ---
  Future<void> createUserSettings(int userId) async {
    Database db = await instance.database;
    final systemSettings = await db.query(systemSettingsTable);
    for (var setting in systemSettings) {
      await db.insert(userSettingsTable, {
        columnUserId: userId,
        columnSettingKey: setting[columnSettingKey],
        columnSettingValue: setting[columnSettingValue],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Map<String, bool>> getAllUserSettings(int userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      userSettingsTable,
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );
    return {
      for (var map in maps) map[columnSettingKey]: map[columnSettingValue] == 'true'
    };
  }

  Future<String?> getUserSetting(int userId, String key) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      userSettingsTable,
      where: '$columnUserId = ? AND $columnSettingKey = ?',
      whereArgs: [userId, key],
    );
    return res.isNotEmpty ? res.first[columnSettingValue] : null;
  }

  Future<void> setUserSetting(int userId, String key, String value) async {
    Database db = await instance.database;
    await db.insert(
      userSettingsTable,
      {
        columnUserId: userId,
        columnSettingKey: key,
        columnSettingValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}