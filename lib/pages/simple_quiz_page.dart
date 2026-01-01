import 'dart:async';

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/result_page.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:examen_civique/widgets/report_problem.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:examen_civique/widgets/shake_widget.dart';
import 'package:flutter/material.dart';

class SimpleQuizPage extends StatefulWidget {
  final Series series;
  final List<Question> questions;
  final int initialIndex;
  final List<int> initialAnswers;
  final int initialTimeSpent;

  SimpleQuizPage({
    super.key,
    required this.series,
    this.initialIndex = 0,
    this.initialAnswers = const [],
    this.initialTimeSpent = 0,
  }) : questions = series.questions;

  @override
  State<SimpleQuizPage> createState() => _SimpleQuizPageState();
}

class _SimpleQuizPageState extends State<SimpleQuizPage>
    with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isCurrentChoiceValidated = false;

  late final List<int> _selections;
  late final Stopwatch _stopwatch;
  late final Timer _timer;

  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;
  double get _progress => (_currentQuestionIndex + 1) / widget.questions.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuiz();
  }

  void _initializeQuiz() {
    _currentQuestionIndex = widget.initialIndex;
    _selections = List<int>.filled(widget.questions.length, -1);
    for (int i = 0; i < widget.initialAnswers.length; i++) {
      if (i < _selections.length) {
        _selections[i] = widget.initialAnswers[i];
      }
    }

    _stopwatch = Stopwatch();
    // We can't set elapsed on stopwatch directly, but we can account for it
    // by adding it when saving/displaying. However, for simplicity in display,
    // we might just want to start it.
    // Actually, to resume time, we need to handle it carefully.
    // Since Stopwatch doesn't allow setting elapsed, we will use a separate variable
    // or just rely on the fact that we save the TOTAL time (initial + current session).
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _timer.cancel();
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

  void _onAnswerSelected(int index) {
    if (_isCurrentChoiceValidated) return;
    setState(() => _selectedAnswerIndex = index);
  }

  Future<void> _validateCurrentChoiceOrShake() async {
    if (_selectedAnswerIndex == null) {
      _shakeKey.currentState?.shake();
      return;
    }

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

    setState(() => _isCurrentChoiceValidated = true);
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

  Future<void> _continue() async {
    _selections[_currentQuestionIndex] = _selectedAnswerIndex!;

    if (_isLastQuestion) {
      _navigateToResults();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isCurrentChoiceValidated = false;
      });
      _saveCurrentState();
    }
  }

  Future<void> _saveProgress(double score) async {
    final db = await AppDb.instance.database;
    final totalTimeSpent =
        Duration(seconds: widget.initialTimeSpent) + _stopwatch.elapsed;

    await Repository(db: db).updateSeriesProgress(widget.series.id, score);
    await Repository(db: db).updateSeriesStats(
      DateTime.now(),
      widget.series.id,
      score,
      totalTimeSpent,
    );
    await Repository(db: db).resetSeriesState(widget.series.id);
  }

  Future<void> _saveCurrentState() async {
    final db = await AppDb.instance.database;
    final totalTimeSpent =
        Duration(seconds: widget.initialTimeSpent) + _stopwatch.elapsed;

    await Repository(db: db).saveSeriesState(
      widget.series.id,
      _currentQuestionIndex,
      _selections,
      totalTimeSpent.inSeconds,
    );
  }

  Future<void> _navigateToResults() async {
    _timer.cancel();
    _stopwatch.stop();

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
          duration:
              Duration(seconds: widget.initialTimeSpent) + _stopwatch.elapsed,
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
              'Série ${widget.series.position} - Q${_currentQuestionIndex + 1}/${widget.questions.length}',
          progress: _progress,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 25),
                  const SizedBox(width: 4.0),
                  Text(
                    formatDuration(
                      Duration(seconds: widget.initialTimeSpent) +
                          _stopwatch.elapsed,
                    ),
                    style: AppTextStyles.medium16,
                  ),
                ],
              ),
            ),
          ],
          onClosePressed: () => yesNoDialog(
            context: context,
            title: 'Souhaites-tu faire une pause\u00A0?',
            content:
                'Ton progrès sera sauvegardé et tu pourras reprendre plus tard.',
            onYesPressed: (context) {
              _saveCurrentState();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit quiz
            },
            onNoPressed: (context) => Navigator.pop(context), // close dialog
          ),
        ),
        body: Container(
          color: AppColors.primaryGreyLight,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
          child: Column(
            children: [
              Expanded(
                child: QuestionSection(
                  question: widget.questions[_currentQuestionIndex],
                  onSelected: _onAnswerSelected,
                  selected: _selectedAnswerIndex,
                  showCorrection: _isCurrentChoiceValidated,
                  shakeKey: _shakeKey,
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                text: _isCurrentChoiceValidated ? 'Continuer' : 'Valider',
                onPressed: _isCurrentChoiceValidated
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

// ===== Helper Widgets
class QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double? progress;
  final List<Widget>? actions;
  final VoidCallback onClosePressed;

  const QuizAppBar({
    super.key,
    required this.title,
    this.progress,
    required this.onClosePressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50 + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      toolbarHeight: 50,
      centerTitle: true,
      title: Text(title, style: AppTextStyles.regular16),
      leading: IconButton(
        onPressed: onClosePressed,
        icon: const Icon(Icons.close),
        color: AppColors.primaryGrey,
        iconSize: 25,
      ),
      actions: actions,
      bottom: progress != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(8.0),
              child: LinearProgressIndicator(
                value: progress,
                color: AppColors.primaryNavyBlue,
                backgroundColor: AppColors.divider,
                minHeight: 8.0,
              ),
            )
          : null,
    );
  }
}

class QuestionSection extends StatelessWidget {
  final Question question;
  final ValueChanged<int> onSelected;
  final int? selected;
  final bool showCorrection;
  final GlobalKey<ShakeWidgetState> shakeKey;

  const QuestionSection({
    super.key,
    required this.question,
    required this.onSelected,
    required this.selected,
    required this.showCorrection,
    required this.shakeKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            ShakeWidget(
              key: shakeKey,
              child: QuestionCard(
                question: question,
                onSelected: onSelected,
                selected: selected,
                showCorrection: showCorrection,
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () => showReportProblemDialog(context, question),
                icon: const Icon(
                  Icons.flag_rounded,
                  size: 20,
                  color: AppColors.primaryGrey,
                ),
                label: Text(
                  'Signaler un problème',
                  style: AppTextStyles.regular13,
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
        const BottomFade(),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavyBlue,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 120.0,
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.regular18.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const DialogButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Text(
          text,
          style: AppTextStyles.medium16.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
