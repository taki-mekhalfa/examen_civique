import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Map<String, dynamic> _parseGzipJson(Uint8List gzBytes) {
  final bytes = GZipCodec().decode(gzBytes);
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

class AppDb {
  static final AppDb instance = AppDb._instance();
  AppDb._instance();
  factory AppDb() => instance;

  Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final dbPath = join(
      (await getApplicationDocumentsDirectory()).path,
      'app.db',
    );

    developer.log('Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedData(db);
      },
    );
  }

  Future<void> _seedData(Database db) async {
    final byteData = await rootBundle.load('assets/data/series.json.gz');
    final gz = byteData.buffer.asUint8List();

    final Map<String, dynamic> data = await compute(_parseGzipJson, gz);
    final List<dynamic> series = (data['series']) as List<dynamic>;
    final List<dynamic> questions = (data['questions']) as List<dynamic>;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final q in questions) {
        batch.insert('questions', {
          'id': q['id'],
          'text': q['text'],
          'choices': jsonEncode(List<String>.from(q['choices'] as List)),
          'answer': q['answer'],
          'explanation': q['explanation'],
          'topic': q['topic'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final s in series) {
        batch.insert('series', {
          'id': s['id'],
          'type': s['type'],
          'position': s['position'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final qId in s['questionIds'] as List) {
          batch.insert('series_questions', {
            'series_id': s['id'],
            'question_id': qId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
    });
  }

  static const List<String> _schemaV1 = [
    _seriesTable,
    _questionsTable,
    _seriesQuestionsTable,
    _seriesQuestionsIndexOnSeriesId,
    _seriesQuestionsIndexOnQId,
  ];

  Future<void> _createSchema(Database db) async {
    for (final sql in _schemaV1) {
      await db.execute(sql);
    }
  }

  static const String _seriesTable = '''
  CREATE TABLE series (
    id INTEGER PRIMARY KEY,
    type INTEGER NOT NULL CHECK (type IN (0, 1)), -- 0 = simple, 1 = exam
    position INTEGER NOT NULL,
    --- progress indicators
    last_answers TEXT, -- JSON array of last answers
    last_score REAL,
    best_score REAL,
    attempts_count INTEGER NOT NULL DEFAULT 0,

    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
  )
''';

  static const String _questionsTable = '''
  CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    text TEXT NOT NULL,
    choices TEXT NOT NULL,
    answer INTEGER NOT NULL,
    explanation TEXT NOT NULL,
    topic TEXT NOT NULL
  )
''';

  static const String _seriesQuestionsTable = '''
  CREATE TABLE series_questions (
    series_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    PRIMARY KEY(series_id, question_id),
    FOREIGN KEY(series_id) REFERENCES series(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  )
''';

  static const String _seriesQuestionsIndexOnSeriesId = '''
  CREATE INDEX idx_series_questions_series_id ON series_questions(series_id)
''';

  static const String _seriesQuestionsIndexOnQId = '''
  CREATE INDEX idx_series_questions_question_id ON series_questions(question_id)
''';
}
