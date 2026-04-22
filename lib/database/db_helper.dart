import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    // Inicialización para Desktop (Linux/Windows)
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      final dbPath = await getDatabasesPath();
      // Aseguramos que el directorio exista
      final directory = Directory(dbPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      path = join(dbPath, 'iremember_viviana.db');
    } else {
      path = join(await getDatabasesPath(), 'iremember_viviana.db');
    }

    return await openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            dayOfWeek TEXT,
            dateTime TEXT,
            isDone INTEGER,
            imagePath TEXT,
            anticipationDays INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE grocery (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item TEXT,
            isDone INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE calculator_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry TEXT
          )
        ''');
        await _createFinanceTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await db.execute('ALTER TABLE tasks ADD COLUMN description TEXT');
        if (oldVersion < 3) await db.execute('ALTER TABLE tasks ADD COLUMN imagePath TEXT');
        if (oldVersion < 4) await db.execute('CREATE TABLE grocery (id INTEGER PRIMARY KEY AUTOINCREMENT, item TEXT, isDone INTEGER)');
        if (oldVersion < 5) await _createFinanceTables(db);
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE tasks ADD COLUMN anticipationDays INTEGER DEFAULT 0');
          await db.execute('CREATE TABLE calculator_history (id INTEGER PRIMARY KEY AUTOINCREMENT, entry TEXT)');
        }
        if (oldVersion < 7) await db.execute('ALTER TABLE finance_settings ADD COLUMN current_savings REAL DEFAULT 0');
        if (oldVersion < 8) await db.execute('ALTER TABLE finance_settings ADD COLUMN savings_goal_name TEXT DEFAULT "Mi Meta"');
      },
    );
  }

  Future<void> _createFinanceTables(Database db) async {
    await db.execute('''
      CREATE TABLE finance_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, amount REAL, category TEXT, date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE finance_settings (
        id INTEGER PRIMARY KEY, savings_goal REAL, total_income REAL, current_savings REAL DEFAULT 0, savings_goal_name TEXT DEFAULT "Mi Meta"
      )
    ''');
    await db.insert('finance_settings', {'id': 1, 'savings_goal': 0, 'total_income': 0, 'current_savings': 0, 'savings_goal_name': 'Mi Meta'});
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('grocery');
    await db.delete('calculator_history');
    await db.delete('finance_transactions');
    await db.update('finance_settings', {'savings_goal': 0, 'total_income': 0, 'current_savings': 0, 'savings_goal_name': 'Mi Meta'}, where: 'id = 1');
  }

  Future<void> addCalcHistory(String entry) async { final db = await database; await db.insert('calculator_history', {'entry': entry}); }
  Future<List<String>> getCalcHistory() async { final db = await database; final res = await db.query('calculator_history', orderBy: 'id DESC'); return res.map((e) => e['entry'] as String).toList(); }
  Future<void> clearCalcHistory() async { final db = await database; await db.delete('calculator_history'); }

  Future<void> addTransaction(String type, double amount, String category) async { final db = await database; await db.insert('finance_transactions', {'type': type, 'amount': amount, 'category': category, 'date': DateTime.now().toIso8601String()}); }
  Future<List<Map<String, dynamic>>> getTransactions() async { final db = await database; return await db.query('finance_transactions', orderBy: 'date DESC'); }
  Future<Map<String, dynamic>> getFinanceSettings() async { final db = await database; return (await db.query('finance_settings', where: 'id = 1')).first; }
  Future<void> updateFinanceSettings(double goal, double income, {double? currentSavings, String? goalName}) async {
    final db = await database;
    Map<String, dynamic> data = {'savings_goal': goal, 'total_income': income};
    if (currentSavings != null) data['current_savings'] = currentSavings;
    if (goalName != null) data['savings_goal_name'] = goalName;
    await db.update('finance_settings', data, where: 'id = 1');
  }
  Future<void> deleteTransaction(int id) async { final db = await database; await db.delete('finance_transactions', where: 'id = ?', whereArgs: [id]); }

  Future<int> insertTask(Task task) async { final db = await database; return await db.insert('tasks', task.toMap()); }
  Future<int> updateTask(Task task) async { final db = await database; return await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]); }
  Future<List<Task>> getTasksByDay(String day) async { final db = await database; final List<Map<String, dynamic>> maps = await db.query('tasks', where: 'dayOfWeek = ?', whereArgs: [day]); return List.generate(maps.length, (i) => Task.fromMap(maps[i])); }
  Future<List<Task>> getTasksByDate(DateTime date) async { final db = await database; final String dateStr = date.toIso8601String().substring(0, 10); final List<Map<String, dynamic>> maps = await db.query('tasks', where: "dateTime LIKE ?", whereArgs: ['$dateStr%']); return List.generate(maps.length, (i) => Task.fromMap(maps[i])); }
  Future<int> updateTaskStatus(int id, bool isDone) async { final db = await database; return await db.update('tasks', {'isDone': isDone ? 1 : 0}, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteTask(int id) async { final db = await database; return await db.delete('tasks', where: 'id = ?', whereArgs: [id]); }

  Future<int> insertGrocery(String item) async { final db = await database; return await db.insert('grocery', {'item': item, 'isDone': 0}); }
  Future<List<Map<String, dynamic>>> getGroceries() async { final db = await database; return await db.query('grocery'); }
  Future<int> updateGroceryStatus(int id, bool isDone) async { final db = await database; return await db.update('grocery', {'isDone': isDone ? 1 : 0}, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteGrocery(int id) async { final db = await database; return await db.delete('grocery', where: 'id = ?', whereArgs: [id]); }
}