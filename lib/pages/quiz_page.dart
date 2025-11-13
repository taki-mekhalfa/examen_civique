import 'dart:async';

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/result_page.dart';
import 'package:examen_civique/repositories/series_repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:examen_civique/widgets/shake_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Public API unchanged
class QuizPage extends StatefulWidget {
  final Series series;
  final Duration? timeLimit;
  final List<Question> questions;

  QuizPage({super.key, required this.series, this.timeLimit})
    : questions = series.questions;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  // ===== Constants
  static const _snackDuration = Duration(milliseconds: 1500);
  static const _timerTick = Duration(seconds: 1);
  static const _lowTimeThreshold = Duration(minutes: 5);
  // ===== UI Constants
  static const _progressBarHeight = 8.0;
  static const _toolbarHeight = 50.0;

  // ===== Question state
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isCurrentChoiceValidated = false;
  late final List<int> _selections;

  // ===== Timer state
  Timer? _timer;
  Duration? _remaining;
  bool _isTimeUp = false;

  // ===== Tracking
  late final DateTime _startTime;

  // ===== UI
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();
  final _formatter = NumberFormat('00');

  // ===== Computed
  bool get _isTimed => widget.timeLimit != null;
  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;
  double get _progress => (_currentQuestionIndex + 1) / widget.questions.length;
  Duration get _safeRemaining => _remaining ?? Duration.zero;
  bool get _isLowTime => _isTimed && _safeRemaining <= _lowTimeThreshold;
  bool get _showQuestionCorrectAnswer => !_isTimed && _isCurrentChoiceValidated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuiz();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause/resume timer when app backgrounded/foregrounded
    if (!_isTimed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isTimeUp && _safeRemaining > Duration.zero) {
        _startTimer();
      }
    }
  }

  void _cleanupResources() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  // ===== Initialization
  void _initializeQuiz() {
    _selections = List<int>.filled(widget.questions.length, -1);
    _startTime = DateTime.now();

    if (_isTimed) {
      _remaining = widget.timeLimit;
      _startTimer();
    }
  }

  // ===== Timer management
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_timerTick, (timer) {
      if (!mounted) return;

      setState(() {
        final next = _safeRemaining - _timerTick;
        if (next <= Duration.zero) {
          _remaining = Duration.zero;
          _isTimeUp = true;
          _timer?.cancel();
          _handleTimeUp();
        } else {
          _remaining = next;
        }
      });
    });
  }

  Future<void> _handleTimeUp() async {
    _timer?.cancel();
    if (!mounted) return;

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
            'Temps écoulé !',
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

  void _validateCurrentChoiceOrShake() {
    if (_selectedAnswerIndex == null) {
      _shakeKey.currentState?.shake();
      return;
    }
    setState(() => _isCurrentChoiceValidated = true);
  }

  void _continueOrShake() {
    if (_selectedAnswerIndex == null) {
      _shakeKey.currentState?.shake();
      return;
    }

    _selections[_currentQuestionIndex] = _selectedAnswerIndex!;

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
    await SeriesRepository(
      db: db,
    ).updateSeriesProgress(widget.series.id, score);
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

    await _saveProgress(score);

    await retryForever(() => _saveProgress(score));

    if (!navigator.mounted) return;

    navigator.pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          series: widget.series,
          selections: _selections,
          duration: DateTime.now().difference(_startTime),
        ),
      ),
    );
  }

  // ===== Formatting
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${_formatter.format(hours)}:${_formatter.format(minutes)}:${_formatter.format(seconds)}';
    }
    return '${_formatter.format(minutes)}:${_formatter.format(seconds)}';
  }

  // ===== UI
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: _QuizAppBar(
          title:
              'Série ${widget.series.id} - Q${_formatter.format(_currentQuestionIndex + 1)}/${_formatter.format(widget.questions.length)}',
          progress: _progress,
          isTimed: _isTimed,
          remainingText: _formatDuration(_safeRemaining),
          isLowTime: _isLowTime,
          onClosePressed: () => _showExitDialog(context),
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
                  child: _QuestionSection(
                    question: widget.questions[_currentQuestionIndex],
                    onSelected: _onAnswerSelected,
                    selected: _selectedAnswerIndex,
                    showCorrection: _showQuestionCorrectAnswer,
                  ),
                ),
                const SizedBox(height: 8),
                _PrimaryButton(
                  text: (_isTimed || _isCurrentChoiceValidated)
                      ? 'Continuer'
                      : 'Valider',
                  onPressed: (_isTimed || _isCurrentChoiceValidated)
                      ? _continueOrShake
                      : _validateCurrentChoiceOrShake,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Dialogs
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text(
            'Souhaites-tu vraiment quitter ?',
            style: AppTextStyles.medium20,
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: AppColors.primaryGreyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        actionsAlignment: MainAxisAlignment.center,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 24.0,
        ),
        content: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: const Text(
            'Si tu quittes maintenant, ton progrès sera perdu.',
            style: AppTextStyles.regular14,
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          _DialogButton(
            text: 'Oui',
            color: AppColors.red,
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit quiz
            },
          ),
          _DialogButton(
            text: 'Non',
            color: AppColors.primaryNavyBlue,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ===== Helper Widgets
class _QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double progress;
  final bool isTimed;
  final String remainingText;
  final bool isLowTime;
  final VoidCallback onClosePressed;

  const _QuizAppBar({
    required this.title,
    required this.progress,
    required this.isTimed,
    required this.remainingText,
    required this.isLowTime,
    required this.onClosePressed,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(_QuizPageState._toolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      toolbarHeight: _QuizPageState._toolbarHeight,
      centerTitle: true,
      title: Text(title, style: AppTextStyles.regular16),
      leading: IconButton(
        onPressed: onClosePressed,
        icon: const Icon(Icons.close),
        color: AppColors.primaryGrey,
        iconSize: 25,
      ),
      actions: isTimed
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 25),
                    const SizedBox(width: 4.0),
                    Text(
                      remainingText,
                      style: AppTextStyles.medium16.copyWith(
                        color: isLowTime
                            ? AppColors.red
                            : AppColors.primaryGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_QuizPageState._progressBarHeight),
        child: LinearProgressIndicator(
          value: progress,
          color: AppColors.primaryNavyBlue,
          backgroundColor: AppColors.divider,
          minHeight: _QuizPageState._progressBarHeight,
        ),
      ),
    );
  }
}

class _QuestionSection extends StatelessWidget {
  final Question question;
  final ValueChanged<int> onSelected;
  final int? selected;
  final bool showCorrection;

  const _QuestionSection({
    required this.question,
    required this.onSelected,
    required this.selected,
    required this.showCorrection,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            ShakeWidget(
              key: (context.findAncestorStateOfType<_QuizPageState>())
                  ?._shakeKey,
              child: QuestionCard(
                question: question,
                onSelected: onSelected,
                selected: selected,
                showCorrection: showCorrection,
              ),
            ),
          ],
        ),
        const BottomFade(),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.text, required this.onPressed});

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

class _DialogButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _DialogButton({
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
