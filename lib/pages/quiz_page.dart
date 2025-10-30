import 'dart:async';

import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/result_page.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:examen_civique/widgets/shake_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuizPage extends StatefulWidget {
  final List<Question> questions;

  final Duration? timeLimit;

  const QuizPage({super.key, required this.questions, this.timeLimit});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  bool _isAnswerValidated = false;
  int? _selectedAnswerIndex;

  // Track all selections and start time
  late final List<int> _selections;
  late final DateTime _startTime;

  // Timer state (for examens blancs)
  Timer? _timer;
  Duration? _remaining;
  bool _isTimeUp = false;

  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  bool get _isTimed => widget.timeLimit != null;
  bool get _showCorrectAnswer => !_isTimed && _isAnswerValidated;

  final formatter = NumberFormat('00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selections = List.generate(widget.questions.length, (index) => -1);
    _startTime = DateTime.now();

    if (_isTimed) {
      _remaining = widget.timeLimit;
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining! - const Duration(seconds: 1);
        if (_remaining! <= Duration.zero) {
          _remaining = Duration.zero;
          _isTimeUp = true;
          _timer?.cancel();
          _onTimeUp();
        }
      });
    });
  }

  void _onTimeUp() async {
    _timer?.cancel();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            "Temps écoulé !",
            style: AppTextStyles.medium16.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
        ),
        elevation: 1.0,
        width: 200,
        backgroundColor: AppColors.red,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Wait briefly before showing results
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          series: 1,
          questions: widget.questions,
          selections: _selections,
          duration: DateTime.now().difference(_startTime),
        ),
      ),
    );
  }

  void _markSelectedAnswer() {
    _selections[_currentQuestionIndex] = _selectedAnswerIndex!;
  }

  void _onValidateAnswer() {
    setState(() {
      _isAnswerValidated = true;
      _markSelectedAnswer();
    });
  }

  void _onNextQuestion() {
    final isLastQuestion = _currentQuestionIndex == widget.questions.length - 1;

    if (isLastQuestion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            series: 1,
            questions: widget.questions,
            selections: _selections,
            duration: DateTime.now().difference(_startTime),
          ),
        ),
      );

      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
      _isAnswerValidated = false;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    // Show HH:MM:SS if > 59 minutes; otherwise MM:SS
    if (hours > 0) {
      return '${formatter.format(hours)}:${formatter.format(minutes)}:${formatter.format(seconds)}';
    }
    return '${formatter.format(minutes)}:${formatter.format(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final progress = (_currentQuestionIndex + 1) / total;
    final isLowTime = _isTimed && _remaining! <= const Duration(minutes: 5);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          scrolledUnderElevation: 0,
          toolbarHeight: 50.0,
          centerTitle: true,
          title: Text(
            'Série 1 - Q${formatter.format(_currentQuestionIndex + 1)}/${formatter.format(total)}',
            style: AppTextStyles.regular16,
          ),
          leading: IconButton(
            onPressed: () => _showExitDialog(context),
            icon: const Icon(Icons.close),
            color: AppColors.primaryGrey,
            iconSize: 25,
          ),
          actions: [
            if (_isTimed)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 25),
                    const SizedBox(width: 4.0),
                    Text(
                      _formatDuration(_remaining!),
                      style: AppTextStyles.medium16.copyWith(
                        color: isLowTime
                            ? AppColors.red
                            : AppColors.primaryGrey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: progress,
              color: AppColors.primaryNavyBlue,
              backgroundColor: AppColors.divider,
              minHeight: 8.0,
            ),
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
                  child: Stack(
                    children: [
                      ListView(
                        children: [
                          ShakeWidget(
                            key: _shakeKey,
                            child: QuestionCard(
                              question: widget.questions[_currentQuestionIndex],
                              onSelected: (index) {
                                if (_isAnswerValidated) return;
                                setState(() {
                                  _selectedAnswerIndex = index;
                                });
                              },
                              selected: _selectedAnswerIndex,
                              showCorrection: _showCorrectAnswer,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 50.0, // height of fade
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreyLight.withAlpha(0),
                                AppColors.primaryGreyLight.withAlpha(200),
                                AppColors.primaryGreyLight,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Require an answer selection before proceeding
                      if (_selectedAnswerIndex == null) {
                        _shakeKey.currentState?.shake();
                        return;
                      }

                      if (_isTimed) {
                        _markSelectedAnswer();
                        _onNextQuestion();
                        return;
                      }

                      _isAnswerValidated
                          ? _onNextQuestion()
                          : _onValidateAnswer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavyBlue,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                        vertical: 8.0,
                      ),
                      child: SizedBox(
                        width: 90.0,
                        child: Center(
                          child: Text(
                            _isTimed
                                ? "Continuer"
                                : (_isAnswerValidated
                                      ? "Continuer"
                                      : "Valider"),
                            style: AppTextStyles.regular18.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Center(
        child: const Text(
          "Souhaites-tu vraiment quitter ?",
          style: AppTextStyles.medium20,
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: AppColors.primaryGreyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      actionsAlignment: MainAxisAlignment.center,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      content: Container(
        decoration: BoxDecoration(color: AppColors.transparent),
        child: Text(
          textAlign: TextAlign.center,
          "Si tu quittes maintenant, ton progrès sera perdu.",
          style: AppTextStyles.regular14,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => {Navigator.pop(context), Navigator.pop(context)},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
            child: Text(
              "Oui",
              style: AppTextStyles.medium16.copyWith(color: AppColors.white),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavyBlue,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
            child: Text(
              "Non",
              style: AppTextStyles.medium16.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ],
    ),
  );
}
