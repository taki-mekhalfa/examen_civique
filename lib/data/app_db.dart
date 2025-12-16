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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedData(db);
      },
      onUpgrade: (db, _, _) async {
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
        batch.rawInsert(
          '''
          INSERT INTO questions (id, text, choices, answer, explanation, topic, subtopic, level)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            text = excluded.text,
            choices = excluded.choices,
            answer = excluded.answer,
            explanation = excluded.explanation,
            topic = excluded.topic,
            subtopic = excluded.subtopic,
            level = excluded.level
          ''',
          [
            q['id'],
            q['text'],
            jsonEncode(List<String>.from(q['choices'] as List)),
            q['answer'],
            q['explanation'],
            q['topic'],
            q['subtopic'],
            q['level'],
          ],
        );
      }

      for (final s in series) {
        batch.rawInsert(
          '''
          INSERT INTO series (id, type, topic, position)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            type = excluded.type,
            topic = excluded.topic,
            position = excluded.position
          ''',
          [s['id'], s['type'], s['topic'], s['position']],
        );

        int questionPosition = 1;
        for (final qId in s['questionIds'] as List) {
          batch.rawInsert(
            '''
            INSERT INTO series_questions (series_id, question_id, question_position)
            VALUES (?, ?, ?)
            ON CONFLICT(series_id, question_id) DO UPDATE SET
              question_position = excluded.question_position
            ''',
            [s['id'], qId, questionPosition],
          );
          questionPosition++;
        }
      }

      await batch.commit(noResult: true);
    });
  }

  static const List<String> _schemaV1 = [
    _seriesTable,
    _questionsTable,
    _seriesQuestionsTable,
    _wrongQuestionsTable,
    _timeSpentStatsTable,
    _answersStatsTable,
    _seriesStatsTable,
    _seriesQuestionsIndexOnSeriesId,
    _seriesQuestionsIndexOnQId,
    _seriesStatsIndexOnDate,
    _answersStatsIndexOnDate,
  ];

  Future<void> _createSchema(Database db) async {
    for (final sql in _schemaV1) {
      await db.execute(sql);
    }
  }

  static const String _seriesTable = '''
  CREATE TABLE series (
    id INTEGER PRIMARY KEY,
    type INTEGER NOT NULL CHECK (type IN (0, 1, 2)), -- 0 = simple, 1 = exam, 2 = thematics
    topic TEXT NULL, -- only for thematics
    position INTEGER NOT NULL,
    --- progress indicators
    last_score REAL,
    best_score REAL,

    --- save state
    current_question_index INTEGER DEFAULT 0,
    saved_answers TEXT, -- JSON list of integers
    time_spent_secs INTEGER DEFAULT 0,

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
    topic TEXT NOT NULL,
    subtopic TEXT NOT NULL,
    level TEXT
  )
''';

  static const String _seriesQuestionsTable = '''
  CREATE TABLE series_questions (
    series_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    question_position INTEGER NOT NULL,
    PRIMARY KEY(series_id, question_id),
    FOREIGN KEY(series_id) REFERENCES series(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  )
''';

  static const String _wrongQuestionsTable = '''
CREATE TABLE wrong_questions (
  question_id INTEGER PRIMARY KEY,
  FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE ON UPDATE CASCADE
)
''';

  static const String _timeSpentStatsTable = '''
CREATE TABLE time_spent_stats (
  date INTEGER PRIMARY KEY, -- milliseconds since epoch, truncated to the day
  time_spent_secs INTEGER NOT NULL DEFAULT 0
)
''';

  static const String _answersStatsTable = '''
CREATE TABLE answers_stats (
  date INTEGER NOT NULL, -- milliseconds since epoch, truncated to the day
  topic TEXT NOT NULL,
  correct_count INTEGER NOT NULL DEFAULT 0,
  incorrect_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(date, topic)
)
''';

  static const String _seriesStatsTable = '''
CREATE TABLE series_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL, -- milliseconds since epoch, truncated to the day
  series_id INTEGER NOT NULL,
  score REAL NOT NULL,
  duration_secs INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(series_id) REFERENCES series(id) ON DELETE CASCADE ON UPDATE CASCADE
)
''';

  static const String _seriesQuestionsIndexOnSeriesId = '''
  CREATE INDEX idx_series_questions_series_id ON series_questions(series_id)
''';

  static const String _seriesQuestionsIndexOnQId = '''
  CREATE INDEX idx_series_questions_question_id ON series_questions(question_id)
''';

  static const String _seriesStatsIndexOnDate = '''
  CREATE INDEX idx_series_stats_date ON series_stats(date)
''';

  static const String _answersStatsIndexOnDate = '''
  CREATE INDEX idx_answers_stats_date ON answers_stats(date)
''';
}
