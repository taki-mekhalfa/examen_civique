import 'dart:async';

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/simple_quiz_page.dart';
import 'package:examen_civique/pages/result_page.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:examen_civique/widgets/shake_widget.dart';
import 'package:flutter/material.dart';

class ExamQuizPage extends StatefulWidget {
  final Series series;
  final Duration timeLimit;
  final List<Question> questions;

  ExamQuizPage({super.key, required this.series, required this.timeLimit})
    : questions = series.questions;

  @override
  State<ExamQuizPage> createState() => _ExamQuizPageState();
}

class _ExamQuizPageState extends State<ExamQuizPage>
    with WidgetsBindingObserver {
  static const _snackDuration = Duration(milliseconds: 1500);
  static const _lowTimeThreshold = Duration(minutes: 5);

  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isCurrentChoiceValidated = false;

  late final List<int> _selections;
  late final Timer _timer;
  late final Stopwatch _stopwatch;

  late Duration _remaining;
  bool _isTimeUp = false;

  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;
  bool get _isLowTime => _remaining <= _lowTimeThreshold;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuiz();
  }

  void _initializeQuiz() {
    _selections = List<int>.filled(widget.questions.length, -1);
    _remaining = widget.timeLimit;
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {
        if (!mounted) return;
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          _isTimeUp = true;
          _handleTimeUp();
        }
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopwatch.stop();
    } else if (state == AppLifecycleState.resumed) {
      _stopwatch.start();
    }
  }

  Future<void> _handleTimeUp() async {
    _timer.cancel();
    _stopwatch.stop();
    _showTimeUpSnackBar();
    await Future.delayed(_snackDuration);
    if (!mounted) return;
    _navigateToResults();
  }

  void _showTimeUpSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Temps écoulé\u00A0!',
            style: AppTextStyles.medium16.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
        ),
        elevation: 1.0,
        width: 200,
        backgroundColor: AppColors.red,
        duration: _snackDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ===== Answer handling
  void _onAnswerSelected(int index) {
    if (_isCurrentChoiceValidated) return;
    setState(() => _selectedAnswerIndex = index);
  }

  Future<void> _addWrongQuestion(int questionId) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).addWrongQuestion(questionId);
  }

  Future<void> _updateAnswersStats(
    DateTime date,
    String topic,
    bool isCorrect,
  ) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).updateAnswersStats(date, topic, isCorrect);
  }

  Future<void> _continueOrShake() async {
    if (_selectedAnswerIndex == null) {
      _shakeKey.currentState?.shake();
      return;
    }

    _selections[_currentQuestionIndex] = _selectedAnswerIndex!;

    final bool isCorrect = widget.questions[_currentQuestionIndex].isCorrect(
      _selectedAnswerIndex!,
    );

    try {
      if (!isCorrect) {
        await _addWrongQuestion(widget.questions[_currentQuestionIndex].id);
      }

      await _updateAnswersStats(
        DateTime.now(),
        widget.questions[_currentQuestionIndex].topic,
        isCorrect,
      );
    } catch (_) {}

    if (_isLastQuestion) {
      _navigateToResults();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isCurrentChoiceValidated = false;
      });
    }
  }

  Future<void> _saveProgress(double score) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).updateSeriesProgress(widget.series.id, score);
    await Repository(db: db).updateSeriesStats(
      DateTime.now(),
      widget.series.id,
      score,
      _stopwatch.elapsed,
    );
  }

  Future<void> _navigateToResults() async {
    final correct = _selections.indexed
        .where((e) => widget.questions[e.$1].answer == e.$2)
        .length;
    final double score = correct / widget.questions.length;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogScreenLoader(),
    );
    final navigator = Navigator.of(context);

    await retryForever(() => _saveProgress(score));

    if (!navigator.mounted) return;

    navigator.pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          series: widget.series,
          selections: _selections,
          duration: widget.timeLimit - _remaining,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: QuizAppBar(
          title:
              'Série ${widget.series.id} - Q${_currentQuestionIndex + 1}/${widget.questions.length}',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 25),
                  const SizedBox(width: 4.0),
                  Text(
                    formatDuration(_remaining),
                    style: AppTextStyles.medium16.copyWith(
                      color: _isLowTime ? AppColors.red : AppColors.primaryGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onClosePressed: () => yesNoDialog(
            context: context,
            title: 'Souhaites-tu vraiment quitter\u00A0?',
            content: 'Si tu quittes maintenant, ton progrès sera perdu.',
            onYesPressed: (context) => {
              Navigator.pop(context), // close dialog
              Navigator.pop(context), // exit quiz
            },
            onNoPressed: (context) => Navigator.pop(context), // close dialog
          ),
        ),
        body: AbsorbPointer(
          absorbing: _isTimeUp,
          child: Container(
            color: AppColors.primaryGreyLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 30.0,
            ),
            child: Column(
              children: [
                Expanded(
                  child: QuestionSection(
                    question: widget.questions[_currentQuestionIndex],
                    onSelected: _onAnswerSelected,
                    selected: _selectedAnswerIndex,
                    showCorrection: false,
                    shakeKey: _shakeKey,
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(text: 'Continuer', onPressed: _continueOrShake),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
