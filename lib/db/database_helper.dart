import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_id TEXT NOT NULL,
        type TEXT NOT NULL,
        recd_date TEXT NOT NULL,
        requestor_name TEXT NOT NULL,
        requestor_location TEXT NOT NULL,
        subject TEXT NOT NULL,
        incoming_images TEXT,
        response_images TEXT,
        forwarded_dept TEXT,
        forwarded_person TEXT,
        expected_closure_date TEXT,
        response_sent_date TEXT,
        actual_closure_date TEXT,
        status TEXT NOT NULL,
        remarks TEXT,
        followup_date TEXT
      )
    ''');
  }

  Future<int> insertRecord(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('records', row);
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    Database db = await instance.database;
    return await db.query('records', orderBy: 'id DESC');
  }

  Future<int> getCountByType(String type) async {
    Database db = await instance.database;
    var x = await db.rawQuery('SELECT COUNT(*) FROM records WHERE type = ?', [type]);
    int? count = Sqflite.firstIntValue(x);
    return count ?? 0;
  }
// Get all records
Future<List<Map<String, dynamic>>> getAllRecords() async {
  final db = await database;
  return await db.query('records', orderBy: 'id DESC');
}

// Delete a record by id
Future<void> deleteRecord(int id) async {
  final db = await database;
  await db.delete('records', where: 'id = ?', whereArgs: [id]);
}

// Update a record (expects a map with 'id' key)
Future<void> updateRecord(Map<String, dynamic> row) async {
  final db = await database;
  await db.update(
    'records',
    row,
    where: 'id = ?',
    whereArgs: [row['id']],
  );
}

Future<int> getTodayFollowupCount() async {
  final db = await database;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final result = await db.rawQuery(
    "SELECT COUNT(*) as cnt FROM records WHERE status != 'Closed' AND followup_date = ?",
    [today],
  );
  return Sqflite.firstIntValue(result) ?? 0;
}
Future<List<Map<String, dynamic>>> getTodayOpenFollowups(String today) async {
  final db = await database;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return await db.rawQuery(
    "SELECT * FROM records WHERE status != 'Closed' AND followup_date = ?",
    [today],
  );
}

}

