class Series {
  final int id;
  final List<Question> questions;

  Series({required this.id, required this.questions});
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
