enum SeriesType { simple, exam }

extension SeriesTypeExtension on SeriesType {
  int get value {
    switch (this) {
      case SeriesType.simple:
        return 0;
      case SeriesType.exam:
        return 1;
    }
  }
}

class Series {
  final int id;
  final int position;
  final List<Question> questions;

  Series({required this.id, required this.position, required this.questions});
}

class Question {
  final int id;
  final String text;
  final List<String> choices;
  final int answer;
  final String explanation;
  final String topic;

  Question({
    required this.id,
    required this.text,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.topic,
  });
}
