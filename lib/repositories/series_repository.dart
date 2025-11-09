import 'dart:convert';
import 'package:examen_civique/models/series.dart';
import 'package:sqflite/sqflite.dart';

class SeriesRepository {
  final Database db;

  SeriesRepository({required this.db});

  Future<List<SeriesProgress>> getSeriesProgressByType(int type) async {
    final seriesResult = await db.query(
      'series',
      columns: [
        'id',
        'position',
        'type',
        'last_answers',
        'last_score',
        'best_score',
        'attempts_count',
      ],
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'position',
    );

    return seriesResult.map((s) => SeriesProgress.fromMap(s)).toList();
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
  final List<int>? lastAnswers;
  final int attemptsCount;

  SeriesProgress({
    required this.id,
    required this.type,
    required this.position,
    required this.lastScore,
    required this.bestScore,
    required this.lastAnswers,
    required this.attemptsCount,
  });

  factory SeriesProgress.fromMap(Map<String, Object?> r) {
    final ansJson = r['last_answers'] as String?;
    return SeriesProgress(
      id: r['id'] as int,
      type: SeriesType.values[r['type'] as int],
      position: r['position'] as int,
      lastScore: (r['last_score'] as num?)?.toDouble(),
      bestScore: (r['best_score'] as num?)?.toDouble(),
      lastAnswers: ansJson == null
          ? null
          : List<int>.from(jsonDecode(ansJson) as List),
      attemptsCount: (r['attempts_count'] as int?) ?? 0,
    );
  }
}
