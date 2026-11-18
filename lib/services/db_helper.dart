import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MobileVaultDatabase {
  static final MobileVaultDatabase instance = MobileVaultDatabase._init();
  static Database? _database;

  MobileVaultDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_vault_mobile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Schema matching what you designed conceptually
    await db.execute('''
      CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE,
        html TEXT,
        timestamp TEXT,
        size_bytes INTEGER
      )
    ''');
  }

  /// Saves or updates a cached page using Upsert
  Future<int> savePage(String url, String html) async {
    final db = await instance.database;
    final sizeBytes = html.length;
    final timestamp = DateTime.now().toIso8601String();

    return await db.rawInsert('''
      INSERT OR REPLACE INTO pages (url, html, timestamp, size_bytes)
      VALUES (?, ?, ?, ?)
    ''', [url, html, timestamp, sizeBytes]);
  }

  /// Loads a cached page by URL
  Future<Map<String, dynamic>?> getPage(String url) async {
    final db = await instance.database;
    final results = await db.query(
      'pages',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }

  /// Pulls dynamic numbers for your Dashboard cards
  Future<Map<String, dynamic>> getStats() async {
    final db = await instance.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM pages');
    final sizeResult = await db.rawQuery('SELECT COALESCE(SUM(size_bytes), 0) as total_size FROM pages');

    final count = Sqflite.firstIntValue(countResult) ?? 0;
    final totalBytes = Sqflite.firstIntValue(sizeResult) ?? 0;
    final sizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(2);

    return {
      'count': count,
      'size_mb': '$sizeMb MB',
    };
  }

  /// Clears database cache
  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('pages');
  }
}