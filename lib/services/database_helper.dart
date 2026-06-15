import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  // Singleton pattern – only one instance of this class
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nenavi.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Create the scores table with patient_uid and timestamp
        await db.execute('''
          CREATE TABLE scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,                 -- store as YYYY-MM-DD
            time TEXT,                 -- store time HH:MM:SS
            composite_score INTEGER,
            domain_scores TEXT,        -- JSON string
            difficulty TEXT,
            patient_uid TEXT,
            timestamp INTEGER          -- milliseconds since epoch for sorting
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE scores ADD COLUMN patient_uid TEXT');
          } catch (e) {
            // ignore if column already exists
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE scores ADD COLUMN time TEXT');
            await db.execute('ALTER TABLE scores ADD COLUMN timestamp INTEGER');
            // Remove UNIQUE constraint by recreating the table
            await db.execute('ALTER TABLE scores RENAME TO scores_old');
            await db.execute('''
              CREATE TABLE scores (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                time TEXT,
                composite_score INTEGER,
                domain_scores TEXT,
                difficulty TEXT,
                patient_uid TEXT,
                timestamp INTEGER
              )
            ''');
            await db.execute('''
              INSERT INTO scores (id, date, composite_score, domain_scores, difficulty, patient_uid)
              SELECT id, date, composite_score, domain_scores, difficulty, patient_uid FROM scores_old
            ''');
            await db.execute('DROP TABLE scores_old');
          } catch (e) {
            debugPrint('Migration error: $e');
          }
        }
      },
    );
  }

  // Insert a new score (or replace if date already exists)
  Future<void> insertScore(Map<String, dynamic> score) async {
    final db = await database;
    await db.insert(
      'scores',
      score,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all scores sorted by date (filtered by patient UID if provided)
  Future<List<Map<String, dynamic>>> getAllScores({String? patientUid}) async {
    final db = await database;
    if (patientUid == null || patientUid.isEmpty) {
      return [];
    }
    return await db.query(
      'scores',
      where: 'patient_uid = ?',
      whereArgs: [patientUid],
      orderBy: 'date ASC',
    );
  }

  // Get the latest score (filtered by patient UID if provided)
  Future<Map<String, dynamic>?> getLatestScore({String? patientUid}) async {
    final db = await database;
    final uid = patientUid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    final List<Map<String, dynamic>> results = await db.query(
      'scores',
      where: 'patient_uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }
}
