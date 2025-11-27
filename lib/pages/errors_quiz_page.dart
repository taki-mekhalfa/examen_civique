import 'dart:async';
import 'dart:collection';

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/errors_page.dart';
import 'package:examen_civique/pages/simple_quiz_page.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/shake_widget.dart';
import 'package:flutter/material.dart';

/// Public API unchanged
class ErrorsQuiz extends StatefulWidget {
  final Queue<Question> questions;

  ErrorsQuiz({super.key, required List<Question> questions})
    : questions = Queue.from(questions);

  @override
  State<ErrorsQuiz> createState() => _ErrorsQuizState();
}

class _ErrorsQuizState extends State<ErrorsQuiz> {
  int? _selectedAnswerIndex;
  bool _isCurrentChoiceValidated = false;

  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  bool get _isLastQuestion => widget.questions.isEmpty;

  @override
  void initState() {
    super.initState();
  }

  void _onAnswerSelected(int index) {
    if (_isCurrentChoiceValidated) return;
    setState(() => _selectedAnswerIndex = index);
  }

  Future<void> _addWrongQuestion(int questionId) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).addWrongQuestion(questionId);
  }

  Future<void> _removeWrongQuestion(int questionId) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).removeWrongQuestion(questionId);
  }

  Future<void> _validateCurrentChoiceOrShake() async {
    if (_selectedAnswerIndex == null) {
      _shakeKey.currentState?.shake();
      return;
    }

    final isCorrect = widget.questions.first.isCorrect(_selectedAnswerIndex!);
    if (isCorrect) {
      retryForever(() => _removeWrongQuestion(widget.questions.first.id));
    } else {
      retryForever(() => _addWrongQuestion(widget.questions.first.id));
    }

    setState(() => _isCurrentChoiceValidated = true);
  }

  _continue() {
    final question = widget.questions.removeFirst();
    final isCorrect = question.isCorrect(_selectedAnswerIndex!);
    if (!isCorrect) {
      widget.questions.addLast(question);
    }

    if (_isLastQuestion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NoMoreErrorsPage()),
      );
    } else {
      setState(() {
        _selectedAnswerIndex = null;
        _isCurrentChoiceValidated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: QuizAppBar(
          title: widget.questions.length == 1
              ? 'Erreur restante'
              : 'Erreurs restantes\u00A0: ${widget.questions.length}',
          onClosePressed: () => yesNoDialog(
            context: context,
            title: 'Souhaites-tu vraiment quitter\u00A0?',
            onYesPressed: (context) => {
              Navigator.pop(context), // close dialog
              Navigator.pop(context), // exit quiz
            },
            onNoPressed: (context) => Navigator.pop(context),
          ),
        ),
        body: Container(
          color: AppColors.primaryGreyLight,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
          child: Column(
            children: [
              Expanded(
                child: QuestionSection(
                  question: widget.questions.first,
                  onSelected: _onAnswerSelected,
                  selected: _selectedAnswerIndex,
                  showCorrection: _isCurrentChoiceValidated,
                  shakeKey: _shakeKey,
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                text: (_isCurrentChoiceValidated) ? 'Continuer' : 'Valider',
                onPressed: (_isCurrentChoiceValidated)
                    ? _continue
                    : _validateCurrentChoiceOrShake,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
