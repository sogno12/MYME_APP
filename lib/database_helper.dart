import 'dart:io';
import 'package:myme_app/screens/system_settings_screen.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:myme_app/models/habit_model.dart';
import 'package:myme_app/models/habit_log_model.dart';
import 'package:myme_app/models/tag_model.dart';

class DatabaseHelper {
  static final _databaseName = "MyMe.db";
  static final _databaseVersion = 8;

  // --- 테이블 이름 ---
  static final usersTable = 'users';
  static final systemSettingsTable = 'system_settings';
  static final userSettingsTable = 'user_settings';
  static final booksTable = 'books';
  static final readLogsTable = 'read_logs';
  static final habitsTable = 'habits';
  static final habitLogsTable = 'habit_logs';
  static final tagsTable = 'tags';
  static final habitTagsTable = 'habit_tags';


  // --- 공통 컬럼 ---
  static final columnId = '_id';

  // --- users 테이블 컬럼 ---
  static final columnEmail = 'email';
  static final columnPassword = 'password';
  static final columnName = 'name';
  static final columnNickname = 'nickname';
  static final columnIsAdmin = 'isAdmin';

  // --- settings 테이블 공통 컬럼 ---
  static final columnSettingKey = 'key';
  static final columnSettingValue = 'value';
  static final columnUserId = 'user_id';

  // --- books, read_logs 공통 컬럼 ---
  static final columnCreatedAt = 'created_at';
  static final columnUpdatedAt = 'updated_at';
  static final columnOwnerId = 'owner_id';
  static final columnCreatedBy = 'created_by';
  static final columnUpdatedBy = 'updated_by';

  // --- books 테이블 컬럼 ---
  static final columnTitle = 'title';
  static final columnAuthors = 'authors';
  static final columnPublisher = 'publisher';
  static final columnIsbn = 'isbn';
  static final columnTotalPages = 'total_pages';
  static final columnThumbnailUrl = 'thumbnail_url';
  static final columnTranslators = 'translators';
  static final columnStatus = 'status';
  static final columnRating = 'rating';
  static final columnNotes = 'notes';
  static final columnManualStartDate = 'manual_start_date';
  static final columnManualEndDate = 'manual_end_date';

  // --- read_logs 테이블 컬럼 ---
  static final columnBookId = 'book_id';
  static final columnReadingDate = 'reading_date';
  static final columnEndPage = 'end_page';
  static final columnDuration = 'duration';
  static final columnMood = 'mood';


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
    
    await db.execute('''
          CREATE TABLE $systemSettingsTable (
            $columnSettingKey TEXT PRIMARY KEY,
            $columnSettingValue TEXT NOT NULL
          )
          ''');

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

    await db.execute('''
          CREATE TABLE $booksTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnCreatedAt TEXT NOT NULL,
            $columnUpdatedAt TEXT NOT NULL,
            $columnOwnerId INTEGER NOT NULL,
            $columnCreatedBy INTEGER NOT NULL,
            $columnUpdatedBy INTEGER NOT NULL,
            $columnTitle TEXT NOT NULL,
            $columnAuthors TEXT NOT NULL,
            $columnPublisher TEXT,
            $columnIsbn TEXT,
            $columnTotalPages INTEGER,
            $columnThumbnailUrl TEXT,
            $columnTranslators TEXT,
            $columnStatus TEXT NOT NULL,
            $columnRating REAL,
            $columnNotes TEXT,
            $columnManualStartDate TEXT,
            $columnManualEndDate TEXT,
            FOREIGN KEY ($columnOwnerId) REFERENCES $usersTable ($columnId) ON DELETE CASCADE
          )
          ''');

    await db.execute('''
          CREATE TABLE $readLogsTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnCreatedAt TEXT NOT NULL,
            $columnUpdatedAt TEXT NOT NULL,
            $columnOwnerId INTEGER NOT NULL,
            $columnCreatedBy INTEGER NOT NULL,
            $columnUpdatedBy INTEGER NOT NULL,
            $columnBookId INTEGER NOT NULL,
            $columnReadingDate TEXT NOT NULL,
            $columnEndPage INTEGER NOT NULL,
            $columnDuration INTEGER,
            $columnNotes TEXT,
            $columnMood TEXT,
            FOREIGN KEY ($columnBookId) REFERENCES $booksTable ($columnId) ON DELETE CASCADE
          )
          ''');
    
    await db.execute('''
      CREATE TABLE $habitsTable (
        id TEXT PRIMARY KEY,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnOwnerId INTEGER NOT NULL,
        $columnCreatedBy INTEGER NOT NULL,
        $columnUpdatedBy INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        emoji TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        tracking_type TEXT NOT NULL,
        goal_unit TEXT,
        show_log_editor_on_check INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY ($columnOwnerId) REFERENCES $usersTable ($columnId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $habitLogsTable (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        memo TEXT,
        is_completed INTEGER NOT NULL DEFAULT 1,
        time_value INTEGER,
        percentage_value INTEGER,
        quantity_value INTEGER,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnOwnerId INTEGER NOT NULL,
        $columnCreatedBy INTEGER NOT NULL,
        $columnUpdatedBy INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES $habitsTable (id) ON DELETE CASCADE,
        FOREIGN KEY ($columnOwnerId) REFERENCES $usersTable ($columnId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tagsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnOwnerId INTEGER NOT NULL,
        $columnCreatedBy INTEGER NOT NULL,
        $columnUpdatedBy INTEGER NOT NULL,
        FOREIGN KEY ($columnOwnerId) REFERENCES $usersTable ($columnId) ON DELETE CASCADE,
        UNIQUE(name, $columnOwnerId)
      )
    ''');

    await db.execute('''
      CREATE TABLE $habitTagsTable (
        habit_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (habit_id, tag_id),
        FOREIGN KEY (habit_id) REFERENCES $habitsTable (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $tagsTable (id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    for (var featureKey in availableFeatures.keys) {
      await db.insert(systemSettingsTable, {
        columnSettingKey: featureKey,
        columnSettingValue: 'true',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final password = '1234';
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    final sognoUserId = await db.insert(usersTable, {
      columnEmail: 'sogno',
      columnPassword: hashedPassword,
      columnNickname: 'sogno',
      columnIsAdmin: 1
    });

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
    await db.execute('DROP TABLE IF EXISTS $usersTable');
    await db.execute('DROP TABLE IF EXISTS $systemSettingsTable');
    await db.execute('DROP TABLE IF EXISTS $userSettingsTable');
    await db.execute('DROP TABLE IF EXISTS $booksTable');
    await db.execute('DROP TABLE IF EXISTS $readLogsTable');
    await db.execute('DROP TABLE IF EXISTS $habitsTable');
    await db.execute('DROP TABLE IF EXISTS $habitLogsTable');
    await db.execute('DROP TABLE IF EXISTS $tagsTable');
    await db.execute('DROP TABLE IF EXISTS $habitTagsTable');
    await _onCreate(db, newVersion);
  }

  // --- User 관련 함수 ---
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
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

  // --- Book Log 관련 함수 ---

  // Book C.R.U.D.
  Future<int> insertBook(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(booksTable, row);
  }

  Future<List<Map<String, dynamic>>> getBooks(
    int ownerId, {
    String? searchQuery,
    String? sortBy,
    String? sortOrder, // 'ASC' or 'DESC'
    String? filterStatus,
  }) async {
    Database db = await instance.database;
    List<String> whereClauses = ['$columnOwnerId = ?'];
    List<dynamic> whereArgs = [ownerId];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('($columnTitle LIKE ? OR $columnAuthors LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    if (filterStatus != null && filterStatus.isNotEmpty) {
      whereClauses.add('$columnStatus = ?');
      whereArgs.add(filterStatus);
    }

    String? orderByClause;
    if (sortBy != null && sortBy.isNotEmpty) {
      String order = (sortOrder == 'DESC') ? 'DESC' : 'ASC';
      switch (sortBy) {
        case 'title':
          orderByClause = '$columnTitle $order';
          break;
        case 'manual_start_date':
          orderByClause = '$columnManualStartDate $order';
          break;
        case 'status':
          orderByClause = '$columnStatus $order';
          break;
        case 'created_at':
          orderByClause = '$columnCreatedAt $order';
          break;
        default:
          orderByClause = '$columnCreatedAt DESC'; // Default sort
          break;
      }
    } else {
      orderByClause = '$columnCreatedAt DESC'; // Default sort if no sortBy is provided
    }

    return await db.query(
      booksTable,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderByClause,
    );
  }

  Future<Map<String, dynamic>?> getBookById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(booksTable, where: '$columnId = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateBook(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(booksTable, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteBook(int id) async {
    Database db = await instance.database;
    return await db.delete(booksTable, where: '$columnId = ?', whereArgs: [id]);
  }

  // ReadLog C.R.U.D.
  Future<int> insertReadLog(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(readLogsTable, row);
  }

  Future<List<Map<String, dynamic>>> getReadLogsForBook(
    int bookId, {
    String? sortBy,
    String? sortOrder, // 'ASC' or 'DESC'
  }) async {
    Database db = await instance.database;
    String? orderByClause;
    if (sortBy != null && sortBy.isNotEmpty) {
      String order = (sortOrder == 'DESC') ? 'DESC' : 'ASC';
      switch (sortBy) {
        case 'reading_date':
          orderByClause = '$columnReadingDate $order';
          break;
        case 'end_page':
          orderByClause = '$columnEndPage $order';
          break;
        case 'duration':
          orderByClause = '$columnDuration $order';
          break;
        default:
          orderByClause = '$columnReadingDate DESC'; // Default sort
          break;
      }
    } else {
      orderByClause = '$columnReadingDate DESC'; // Default sort if no sortBy is provided
    }

    return await db.query(
      readLogsTable,
      where: '$columnBookId = ?',
      whereArgs: [bookId],
      orderBy: orderByClause,
    );
  }

  Future<Map<String, dynamic>?> getReadLogById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(readLogsTable, where: '$columnId = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateReadLog(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(readLogsTable, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteReadLog(int id) async {
    Database db = await instance.database;
    return await db.delete(readLogsTable, where: '$columnId = ?', whereArgs: [id]);
  }

  // --- Habit Tracker 관련 함수 ---

  // Habit C.R.U.D.
  Future<void> insertHabit(Habit habit) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(habitsTable, habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await _updateHabitTags(txn, habit.id, habit.tags);
    });
  }

  Future<Habit?> getHabitById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(habitsTable, where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      final habitMap = res.first;
      final List<Tag> tags = await _getTagsForHabit(db, id);
      return Habit.fromMap(habitMap)..tags = tags;
    }
    return null;
  }

  Future<List<Habit>> getAllHabits(int ownerId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      habitsTable,
      where: '$columnOwnerId = ?',
      whereArgs: [ownerId],
      orderBy: '$columnCreatedAt DESC',
    );
    List<Habit> habits = [];
    for (var map in res) {
      final List<Tag> tags = await _getTagsForHabit(db, map['id']);
      habits.add(Habit.fromMap(map)..tags = tags);
    }
    return habits;
  }

  Future<void> updateHabit(Habit habit) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(habitsTable, habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
      await _updateHabitTags(txn, habit.id, habit.tags);
    });
  }

  Future<int> deleteHabit(String id) async {
    Database db = await instance.database;
    return await db.delete(habitsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Habit-Tag Linking
  Future<void> _updateHabitTags(Transaction txn, String habitId, List<Tag> tags) async {
    await txn.delete(habitTagsTable, where: 'habit_id = ?', whereArgs: [habitId]);
    for (var tag in tags) {
      await txn.insert(habitTagsTable, {'habit_id': habitId, 'tag_id': tag.id});
    }
  }

  Future<List<Tag>> _getTagsForHabit(Database db, String habitId) async {
    final List<Map<String, dynamic>> tagMaps = await db.rawQuery('''
      SELECT T.* FROM $tagsTable T
      INNER JOIN $habitTagsTable HT ON T.id = HT.tag_id
      WHERE HT.habit_id = ?
    ''', [habitId]);
    return tagMaps.map((map) => Tag.fromMap(map)).toList();
  }

  // HabitLog C.R.U.D.
  Future<void> insertHabitLog(HabitLog log) async {
    Database db = await instance.database;
    await db.insert(habitLogsTable, log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HabitLog?> getHabitLogById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(habitLogsTable, where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? HabitLog.fromMap(res.first) : null;
  }

  Future<List<HabitLog>> getHabitLogsForHabit(String habitId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      habitLogsTable,
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return res.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<HabitLog?> getHabitLogForDate(String habitId, DateTime date) async {
    Database db = await instance.database;
    final dateString = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    List<Map<String, dynamic>> res = await db.query(
      habitLogsTable,
      where: 'habit_id = ? AND date LIKE ?',
      whereArgs: [habitId, '$dateString%'],
    );
    return res.isNotEmpty ? HabitLog.fromMap(res.first) : null;
  }

  Future<void> updateHabitLog(HabitLog log) async {
    Database db = await instance.database;
    await db.update(habitLogsTable, log.toMap(), where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteHabitLog(String id) async {
    Database db = await instance.database;
    return await db.delete(habitLogsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Tag C.R.U.D.
  Future<void> insertTag(Tag tag) async {
    Database db = await instance.database;
    await db.insert(tagsTable, tag.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Tag?> getTagById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(tagsTable, where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? Tag.fromMap(res.first) : null;
  }

  Future<List<Tag>> getAllTags(int ownerId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> res = await db.query(
      tagsTable,
      where: '$columnOwnerId = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );
    return res.map((map) => Tag.fromMap(map)).toList();
  }

  Future<void> updateTag(Tag tag) async {
    Database db = await instance.database;
    await db.update(tagsTable, tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<int> deleteTag(String id) async {
    Database db = await instance.database;
    return await db.delete(tagsTable, where: 'id = ?', whereArgs: [id]);
  }
}