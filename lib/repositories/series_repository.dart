import 'dart:convert';
import 'package:examen_civique/models/series.dart';
import 'package:sqflite/sqflite.dart';

class SeriesRepository {
  final Database db;

  SeriesRepository({required this.db});

  Future<List<SeriesProgress>> getSeriesProgressByType(int type) async {
    final seriesResult = await db.query(
      'series',
      columns: ['id', 'position', 'type', 'last_score', 'best_score'],
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'position',
    );

    return seriesResult.map((s) => SeriesProgress.fromMap(s)).toList();
  }

  Future<void> updateSeriesProgress(int id, double score) async {
    await db.rawUpdate(
      '''
      UPDATE series
      SET last_score = ?,
      best_score = MAX(COALESCE(best_score, 0), ?)
      WHERE id = ?
      ''',
      [score, score, id],
    );
  }

  Future<List<Question>> getSeriesQuestions(int seriesId) async {
    final questionsResult = await db.rawQuery(
      '''
      SELECT q.*
      FROM questions q
      INNER JOIN series_questions sq ON q.id = sq.question_id
      WHERE sq.series_id = ?
      ORDER BY sq.question_id
      ''',
      [seriesId],
    );

    return questionsResult.map((q) {
      return Question(
        id: q['id'] as int,
        text: q['text'] as String,
        choices: List<String>.from(jsonDecode(q['choices'] as String)),
        answer: q['answer'] as int,
        explanation: q['explanation'] as String,
        topic: q['topic'] as String,
      );
    }).toList();
  }
}

class SeriesProgress {
  final int id;
  final SeriesType type;
  final int position;
  final double? lastScore;
  final double? bestScore;

  SeriesProgress({
    required this.id,
    required this.type,
    required this.position,
    required this.lastScore,
    required this.bestScore,
  });

  factory SeriesProgress.fromMap(Map<String, Object?> r) {
    return SeriesProgress(
      id: r['id'] as int,
      type: SeriesType.values[r['type'] as int],
      position: r['position'] as int,
      lastScore: (r['last_score'] as num?)?.toDouble(),
      bestScore: (r['best_score'] as num?)?.toDouble(),
    );
  }
}
