import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tank.dart';
import '../models/calculation_history.dart';

class DatabaseService {
  static Database? _database;

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mytank.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  static Future<void> _onCreate(Database db, int version) async {
    // Table: tanks
    await db.execute('''
      CREATE TABLE tanks(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        owner TEXT,
        location TEXT,
        capacity REAL,
        diameter REAL,
        tempRef REAL DEFAULT 32.0,
        koefEkspansi REAL DEFAULT 0.0000348
      )
    ''');

    // Table: calibration
    await db.execute('''
      CREATE TABLE calibration(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tank_id INTEGER NOT NULL,
        meter INTEGER NOT NULL,
        cm INTEGER NOT NULL,
        volume REAL NOT NULL,
        FOREIGN KEY (tank_id) REFERENCES tanks(id) ON DELETE CASCADE
      )
    ''');

    // Table: fraction
    await db.execute('''
      CREATE TABLE fraction(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tank_id INTEGER NOT NULL,
        cincin TEXT NOT NULL,
        heightFrom REAL NOT NULL,
        heightTo REAL NOT NULL,
        mm INTEGER NOT NULL,
        volume REAL NOT NULL,
        FOREIGN KEY (tank_id) REFERENCES tanks(id) ON DELETE CASCADE
      )
    ''');

    // Table: calculation_history
    await _createHistoryTable(db);

  }
  
  // Method untuk membuat tabel history 
   static Future<void> _createHistoryTable(Database db) async {
   await db.execute('''
    CREATE TABLE calculation_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tankId INTEGER NOT NULL,
      tankName TEXT NOT NULL,
      sounding REAL NOT NULL,
      mejaUkur REAL NOT NULL,
      tempDalam REAL NOT NULL,
      tempLuar REAL NOT NULL,
      densityObserved REAL NOT NULL,
      vt REAL NOT NULL,
      vObs REAL NOT NULL,
      vcf REAL NOT NULL,
      v15 REAL NOT NULL,
      d15 REAL NOT NULL,
      timestamp TEXT NOT NULL,
      notes TEXT
    )
   ''');
  }

   // Simpan history perhitungan
   static Future<int> saveHistory(CalculationHistory history) async {
   final db = await database;
   return await db.insert('calculation_history', history.toMap());
   }

  // Get semua history
  static Future<List<CalculationHistory>> getAllHistory() async {
   final db = await database;
   final maps = await db.query(
    'calculation_history',
    orderBy: 'timestamp DESC',
   );
   return maps.map((map) => CalculationHistory.fromMap(map)).toList();
  }

   // Get history by tank ID
  static Future<List<CalculationHistory>> getHistoryByTank(int tankId) async {
   final db = await database;
   final maps = await db.query(
    'calculation_history',
    where: 'tankId = ?',
    whereArgs: [tankId],
    orderBy: 'timestamp DESC',
   );
   return maps.map((map) => CalculationHistory.fromMap(map)).toList();
  }

   // Get history by date range
   static Future<List<CalculationHistory>> getHistoryByDateRange(
   DateTime start,
   DateTime end,
   ) async {
   final db = await database;
   final maps = await db.query(
    'calculation_history',
    where: 'timestamp BETWEEN ? AND ?',
    whereArgs: [start.toIso8601String(), end.toIso8601String()],
    orderBy: 'timestamp DESC',
   );
   return maps.map((map) => CalculationHistory.fromMap(map)).toList();
  }

  /// Get latest history (untuk kalkulator selisih)
   static Future<CalculationHistory?> getLatestHistory(int tankId) async {
   final db = await database;
   final maps = await db.query(
    'calculation_history',
    where: 'tankId = ?',
    whereArgs: [tankId],
    orderBy: 'timestamp DESC',
    limit: 1,
   );
  
   if (maps.isEmpty) return null;
   return CalculationHistory.fromMap(maps.first);
  }

   // Get history by ID
   static Future<CalculationHistory?> getHistoryById(int id) async {
   final db = await database;
   final maps = await db.query(
    'calculation_history',
    where: 'id = ?',
    whereArgs: [id],
   );
  
   if (maps.isEmpty) return null;
   return CalculationHistory.fromMap(maps.first);
  }

   // Update history notes
   static Future<int> updateHistoryNotes(int id, String notes) async {
   final db = await database;
   return await db.update(
    'calculation_history',
    {'notes': notes},
    where: 'id = ?',
    whereArgs: [id],
   );
  }

   // Delete history
   static Future<int> deleteHistory(int id) async {
   final db = await database;
   return await db.delete(
    'calculation_history',
    where: 'id = ?',
    whereArgs: [id],
   );
  }

   // Delete all history for a tank
   static Future<int> deleteHistoryByTank(int tankId) async {
   final db = await database;
   return await db.delete(
    'calculation_history',
    where: 'tankId = ?',
    whereArgs: [tankId],
   );
  }

   // Clear all history
   static Future<int> clearAllHistory() async {
   final db = await database;
   return await db.delete('calculation_history');
  }

   // Get history count
   static Future<int> getHistoryCount() async {
   final db = await database;
   final result = await db.rawQuery('SELECT COUNT(*) as count FROM calculation_history');
   return Sqflite.firstIntValue(result) ?? 0;
  }

   // Get history count by tank
   static Future<int> getHistoryCountByTank(int tankId) async {
   final db = await database;
   final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM calculation_history WHERE tankId = ?',
    [tankId],
   );
   return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== TANKS ====================

  static Future<List<Tank>> getTanks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tanks');
    return List.generate(maps.length, (i) => Tank.fromJson(maps[i]));
  }

  static Future<void> saveTank(Tank tank) async {
    final db = await database;
    if (tank.id == null) {
      tank.id = DateTime.now().millisecondsSinceEpoch;
      await db.insert('tanks', tank.toJson());
    } else {
      await db.update(
        'tanks',
        tank.toJson(),
        where: 'id = ?',
        whereArgs: [tank.id],
      );
    }
  }

  static Future<void> deleteTank(int id) async {
    final db = await database;
    await db.delete('tanks', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CALIBRATION ====================

  static Future<List<CalibrationEntry>> getCalibration(int tankId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration',
      where: 'tank_id = ?',
      whereArgs: [tankId],
    );
    return List.generate(maps.length, (i) => CalibrationEntry.fromJson(maps[i]));
  }

  static Future<void> saveCalibration(int tankId, List<CalibrationEntry> calibration) async {
    final db = await database;
    
    // Delete existing calibration for this tank
    await db.delete('calibration', where: 'tank_id = ?', whereArgs: [tankId]);
    
    // Insert new calibration
    for (var entry in calibration) {
      await db.insert('calibration', {
        'tank_id': tankId,
        'meter': entry.meter,
        'cm': entry.cm,
        'volume': entry.volume,
      });
    }
  }

  // ==================== FRACTION ====================

  static Future<List<FractionEntry>> getFraction(int tankId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fraction',
      where: 'tank_id = ?',
      whereArgs: [tankId],
    );
    return List.generate(maps.length, (i) => FractionEntry.fromJson(maps[i]));
  }

  static Future<void> saveFraction(int tankId, List<FractionEntry> fraction) async {
    final db = await database;
    
    // Delete existing fraction for this tank
    await db.delete('fraction', where: 'tank_id = ?', whereArgs: [tankId]);
    
    // Insert new fraction
    for (var entry in fraction) {
      await db.insert('fraction', {
        'tank_id': tankId,
        'cincin': entry.cincin,
        'heightFrom': entry.heightFrom,
        'heightTo': entry.heightTo,
        'mm': entry.mm,
        'volume': entry.volume,
      });
    }
  }
}