import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expression_result.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance =
      DatabaseService._();

  static const String _databaseName =
      'expression_detection.db';

  static const int _databaseVersion = 1;

  static const String resultsTable =
      'expression_results';

  Database? _database;

  Future<Database> get database async {
    final Database? existingDatabase =
        _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final Database newDatabase =
        await _initializeDatabase();

    _database = newDatabase;

    return newDatabase;
  }

  Future<Database> _initializeDatabase() async {
    final String databaseDirectory =
        await getDatabasesPath();

    final String databasePath = path.join(
      databaseDirectory,
      _databaseName,
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (Database database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: (
        Database database,
        int version,
      ) async {
        await database.execute(
          '''
          CREATE TABLE $resultsTable (
            id TEXT PRIMARY KEY,
            image_path TEXT NOT NULL,
            cropped_face_path TEXT NOT NULL,
            predicted_expression TEXT NOT NULL,
            confidence REAL NOT NULL,
            probabilities TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
          ''',
        );

        await database.execute(
          '''
          CREATE INDEX index_results_created_at
          ON $resultsTable(created_at DESC)
          ''',
        );
      },
    );
  }

  Future<void> insertResult(
    ExpressionResult result,
  ) async {
    try {
      final Database db = await database;

      await db.insert(
        resultsTable,
        result.toMap(),
        conflictAlgorithm:
            ConflictAlgorithm.abort,
      );
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to save result: $error',
      );
    }
  }

  Future<List<ExpressionResult>>
      getAllResults() async {
    try {
      final Database db = await database;

      final List<Map<String, dynamic>> rows =
          await db.query(
        resultsTable,
        orderBy: 'created_at DESC',
      );

      return rows
          .map(ExpressionResult.fromMap)
          .toList();
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to load saved results: $error',
      );
    }
  }

  Future<ExpressionResult?> getResultById(
    String id,
  ) async {
    try {
      final Database db = await database;

      final List<Map<String, dynamic>> rows =
          await db.query(
        resultsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      return ExpressionResult.fromMap(
        rows.first,
      );
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to load result: $error',
      );
    }
  }

  Future<void> deleteResult(
    String id,
  ) async {
    try {
      final Database db = await database;

      await db.delete(
        resultsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to delete result: $error',
      );
    }
  }

  Future<void> deleteAllResults() async {
    try {
      final Database db = await database;

      await db.delete(resultsTable);
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to delete saved results: $error',
      );
    }
  }

  Future<int> getResultsCount() async {
    try {
      final Database db = await database;

      final List<Map<String, Object?>> result =
          await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM $resultsTable
        ''',
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (error) {
      throw DatabaseServiceException(
        'Unable to count results: $error',
      );
    }
  }

  Future<void> close() async {
    final Database? db = _database;

    if (db == null) {
      return;
    }

    await db.close();
    _database = null;
  }
}

class DatabaseServiceException
    implements Exception {
  const DatabaseServiceException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
