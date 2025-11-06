import 'dart:convert';
import 'package:examen_civique/models/series.dart';
import 'package:sqflite/sqflite.dart';

class SeriesRepository {
  Database db;

  SeriesRepository({required this.db});

  Future<Series> getSeriesById(int seriesId) async {
    // Get questions for this series
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

    final questions = questionsResult.map((q) {
      return Question(
        id: q['id'] as int,
        text: q['text'] as String,
        choices: List<String>.from(jsonDecode(q['choices'] as String)),
        answer: q['answer'] as int,
        explanation: q['explanation'] as String,
        topic: q['topic'] as String,
      );
    }).toList();

    return Series(id: seriesId, questions: questions);
  }
}
