import 'dart:convert';
import 'package:examen_civique/models/series.dart';
import 'package:sqflite/sqflite.dart';

class Repository {
  final Database db;

  Repository({required this.db});

  int _dateToTimestamp(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  Future<List<SeriesProgress>> getSeriesProgressByType(int type) async {
    final seriesResult = await db.rawQuery(
      '''
      SELECT 
        s.id, 
        s.position, 
        s.type, 
        s.last_score, 
        s.best_score, 
        s.current_question_index, 
        s.saved_answers, 
        s.time_spent_secs,
        (SELECT COUNT(*) FROM series_questions sq WHERE sq.series_id = s.id) as total_questions
      FROM series s
      WHERE s.type = ?
      ORDER BY s.position
    ''',
      [type],
    );

    return seriesResult.map((s) => SeriesProgress.fromMap(s)).toList();
  }

  Future<void> updateSeriesProgress(int id, double score) async {
    await db.rawUpdate(
      '''
      UPDATE series
      SET last_score = ?,
      best_score = MAX(COALESCE(best_score, 0), ?),
      current_question_index = 0,
      saved_answers = NULL,
      time_spent_secs = 0
      WHERE id = ?
      ''',
      [score, score, id],
    );
  }

  Future<void> saveSeriesState(
    int seriesId,
    int index,
    List<int> answers,
    int timeSpent,
  ) async {
    await db.update(
      'series',
      {
        'current_question_index': index,
        'saved_answers': jsonEncode(answers),
        'time_spent_secs': timeSpent,
      },
      where: 'id = ?',
      whereArgs: [seriesId],
    );
  }

  Future<void> resetSeriesState(int seriesId) async {
    await db.update(
      'series',
      {
        'current_question_index': 0,
        'saved_answers': null,
        'time_spent_secs': 0,
      },
      where: 'id = ?',
      whereArgs: [seriesId],
    );
  }

  Future<List<Question>> getSeriesQuestions(int seriesId) async {
    final questionsResult = await db.rawQuery(
      '''
      SELECT q.*
      FROM questions q
      INNER JOIN series_questions sq ON q.id = sq.question_id
      WHERE sq.series_id = ?
      ORDER BY sq.question_position
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
        subtopic: q['subtopic'] as String,
      );
    }).toList();
  }

  Future<void> addWrongQuestion(int questionId) async {
    await db.insert('wrong_questions', {
      'question_id': questionId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeWrongQuestion(int questionId) async {
    await db.delete(
      'wrong_questions',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> clearWrongQuestions() async {
    await db.delete('wrong_questions');
  }

  Future<int> getWrongQuestionsCount() async {
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as wqcount FROM wrong_questions',
    );
    return countResult.first['wqcount'] as int;
  }

  Future<List<Question>> getWrongQuestions() async {
    final wrongQuestionsResult = await db.rawQuery(
      'SELECT q.* FROM questions q INNER JOIN wrong_questions wq ON q.id = wq.question_id',
    );
    return wrongQuestionsResult.map((q) {
      return Question(
        id: q['id'] as int,
        text: q['text'] as String,
        choices: List<String>.from(jsonDecode(q['choices'] as String)),
        answer: q['answer'] as int,
        explanation: q['explanation'] as String,
        topic: q['topic'] as String,
        subtopic: q['subtopic'] as String,
      );
    }).toList();
  }

  Future<void> updateTimeSpentStats(DateTime date, Duration timeSpent) async {
    final timeSpentSecs = timeSpent.inSeconds;
    final dateTs = _dateToTimestamp(date);
    await db.rawUpdate(
      '''
      INSERT INTO time_spent_stats (date, time_spent_secs)
      VALUES (?, ?)
      ON CONFLICT(date) DO UPDATE SET time_spent_secs = time_spent_secs + ?
      ''',
      [dateTs, timeSpentSecs, timeSpentSecs],
    );
  }

  Future<void> updateAnswersStats(
    DateTime date,
    String topic,
    bool isCorrect,
  ) async {
    final dateTs = _dateToTimestamp(date);
    await db.rawUpdate(
      '''
    INSERT INTO answers_stats (date, topic, correct_count, incorrect_count)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(date, topic) DO UPDATE SET 
      correct_count = correct_count + excluded.correct_count,
      incorrect_count = incorrect_count + excluded.incorrect_count
    ''',
      [dateTs, topic, isCorrect ? 1 : 0, isCorrect ? 0 : 1],
    );
  }

  Future<void> updateSeriesStats(
    DateTime date,
    int seriesId,
    double score,
    Duration duration,
  ) async {
    final durationSecs = duration.inSeconds;
    final dateTs = _dateToTimestamp(date);
    await db.rawUpdate(
      '''
      INSERT INTO series_stats (date, series_id, score, duration_secs)
      VALUES (?, ?, ?, ?)
      ''',
      [dateTs, seriesId, score, durationSecs],
    );
  }

  Future<Statistics> getStatistics(DateTime dayFrom, DateTime dayTo) async {
    final fromMillis = dayFrom.millisecondsSinceEpoch;
    final toMillis = dayTo.millisecondsSinceEpoch;

    // 1. Parallelize Database Calls
    final results = await Future.wait([
      db.rawQuery(
        'SELECT topic, SUM(correct_count) as correct_count, SUM(incorrect_count) as incorrect_count FROM answers_stats WHERE date BETWEEN ? AND ? GROUP BY topic',
        [fromMillis, toMillis],
      ),
      db.rawQuery(
        'SELECT COALESCE(SUM(time_spent_secs),0) as time_spent_secs FROM time_spent_stats WHERE date BETWEEN ? AND ?',
        [fromMillis, toMillis],
      ),
      db.rawQuery(
        'SELECT date, s.type, AVG(ss.score) as score FROM series s JOIN series_stats ss ON s.id = ss.series_id WHERE ss.date BETWEEN ? AND ? GROUP BY date, s.type',
        [fromMillis, toMillis],
      ),
    ]);

    final topicsResult = results[0];
    final timeSpentResult = results[1];
    final seriesResult = results[2];

    // 2. Pre-process results into Maps for O(1) lookup
    // Note: If multiple entries exist for the same date, this logic
    // keeps the last one (matching your original logic).
    final topicsMap = <String, TopicStatistics>{};
    for (final t in topicsResult) {
      final correct = t['correct_count'] as int;
      final incorrect = t['incorrect_count'] as int;

      topicsMap[t['topic'] as String] = TopicStatistics(
        correct: correct,
        total: correct + incorrect,
      );
    }

    final simpleSeriesMap = <int, double>{};
    final mockExamsMap = <int, double>{};

    for (final s in seriesResult) {
      final date = s['date'] as int;
      final score = s['score'] as double;
      final type = s['type'] as int;

      if (type == SeriesType.simple.value) {
        simpleSeriesMap[date] = score;
      } else if (type == SeriesType.exam.value) {
        mockExamsMap[date] = score;
      }
    }

    final simpleSeriesList = <double?>[];
    final mockExamsList = <double?>[];

    // Iterate from start date to end date.
    var currentDay = dayFrom;
    while (!currentDay.isAfter(dayTo)) {
      final currentMillis = currentDay.millisecondsSinceEpoch;
      simpleSeriesList.add(simpleSeriesMap[currentMillis]);
      mockExamsList.add(mockExamsMap[currentMillis]);

      currentDay = currentDay.add(const Duration(days: 1));
    }

    // Safely extract time spent
    final totalSeconds = timeSpentResult.isNotEmpty
        ? (timeSpentResult.first['time_spent_secs'] as int? ?? 0)
        : 0;

    return Statistics(
      from: dayFrom,
      to: dayTo,
      timeSpent: Duration(seconds: totalSeconds),
      topics: topicsMap,
      simpleSeries: simpleSeriesList,
      mockExams: mockExamsList,
    );
  }
}

class SeriesProgress {
  final int id;
  final SeriesType type;
  final int position;
  final double? lastScore;
  final double? bestScore;
  final int currentQuestionIndex;
  final List<int> savedAnswers;
  final int timeSpentSecs;
  final int totalQuestions;

  SeriesProgress({
    required this.id,
    required this.type,
    required this.position,
    required this.lastScore,
    required this.bestScore,
    required this.currentQuestionIndex,
    required this.savedAnswers,
    required this.timeSpentSecs,
    required this.totalQuestions,
  });

  factory SeriesProgress.fromMap(Map<String, Object?> r) {
    final savedAnswersJson = r['saved_answers'] as String?;
    final savedAnswers = savedAnswersJson != null
        ? List<int>.from(jsonDecode(savedAnswersJson))
        : <int>[];

    return SeriesProgress(
      id: r['id'] as int,
      type: SeriesType.values[r['type'] as int],
      position: r['position'] as int,
      lastScore: (r['last_score'] as num?)?.toDouble(),
      bestScore: (r['best_score'] as num?)?.toDouble(),
      currentQuestionIndex: (r['current_question_index'] as int?) ?? 0,
      savedAnswers: savedAnswers,
      timeSpentSecs: (r['time_spent_secs'] as int?) ?? 0,
      totalQuestions: (r['total_questions'] as int?) ?? 0,
    );
  }
}

class TopicStatistics {
  final int correct;
  final int total;
  double get progress => total == 0 ? 0 : correct / total;
  int get percentage => (progress * 100).round();
  TopicStatistics({required this.correct, required this.total});
}

class Statistics {
  final DateTime from;
  final DateTime to;

  final Duration timeSpent; // sum of time spent learning on the app.

  // these statistics are for each topic.
  final Map<String, TopicStatistics> topics;
  // these statistics are for each day between from and to.
  // null if no statistics for that day.
  final List<double?> simpleSeries;
  final List<double?> mockExams;

  Statistics({
    required this.from,
    required this.to,
    required this.timeSpent,
    required this.topics,
    required this.simpleSeries,
    required this.mockExams,
  });

  int get answeredCount => topics.values.fold<int>(0, (s, v) => s + v.total);
  int get correctCount => topics.values.fold<int>(0, (s, v) => s + v.correct);
  double get correctPercentage =>
      answeredCount == 0 ? 0.0 : correctCount / answeredCount;
}
