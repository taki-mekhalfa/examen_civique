import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/quiz_page.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final int series;
  final List<Question> questions;
  final List<int> selections;
  final int correctCount;
  final Duration duration;

  ResultPage({
    super.key,
    required this.series,
    required this.questions,
    required this.selections,
    required this.duration,
  }) : correctCount = selections.indexed.where((entry) {
         final (index, selection) = entry;
         return selection == questions[index].answer;
       }).length;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final Set<int> _expanded = {};
  ViewMode _mode = ViewMode.corrections;

  List<_TopicStat> _computeTopicStats() {
    final Map<String, _TopicStat> map = {};

    for (var i = 0; i < widget.questions.length; i++) {
      final topicName = widget.questions[i].topic;
      final isCorrect = widget.selections[i] == widget.questions[i].answer;

      final stat = map.putIfAbsent(topicName, () => _TopicStat(topicName));
      stat.total++;
      stat.correct += isCorrect ? 1 : 0;
    }

    final stats = map.values.toList();
    // Sort by weakest topics first to show them first.
    // This way, the user can see the weakest topics first and concentrate on them.
    stats.sort((a, b) => a.progress.compareTo(b.progress));
    return stats;
  }

  void _toggleQuestion(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  double get scorePercentage =>
      (widget.correctCount / widget.questions.length) * 100;

  String get scoreMarianne {
    if (scorePercentage >= 80) {
      return "assets/marianne/marianne_bravo.png";
    } else if (scorePercentage >= 60) {
      return "assets/marianne/marianne_bien_joue.png";
    } else if (scorePercentage >= 40) {
      return "assets/marianne/marianne_pas_mal.png";
    } else {
      return "assets/marianne/marianne_courage.png";
    }
  }

  Color get scoreColor {
    if (scorePercentage >= 80) {
      return AppColors.correctGreen;
    } else if (scorePercentage >= 60) {
      return AppColors.primaryNavyBlue;
    } else {
      return AppColors.wrongRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50.0,
        title: Text(
          'Série ${widget.series} - Résultats',
          style: AppTextStyles.regular18,
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: AppColors.primaryGrey,
          iconSize: 25,
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.primaryGreyLight,
            child: ListView(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(scoreMarianne, height: 120.0, width: 300.0),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _ScoreCircle(
                                    correct: widget.correctCount,
                                    total: widget.questions.length,
                                  ),
                                  const SizedBox(width: 5.0),
                                  Expanded(
                                    child: Text(
                                      'Accède au détail des questions pour vérifier tes réponses.',
                                      style: AppTextStyles.regular14.copyWith(
                                        color: AppColors.primaryGrey,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  const SizedBox(width: 8.0),
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                    color: AppColors.primaryGrey,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'Temps écoulé : ${_formatElapsed(widget.duration)}',
                                    style: AppTextStyles.medium14.copyWith(
                                      color: AppColors.primaryGrey,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10.0),
                              _ModeToggle(
                                mode: _mode,
                                onChanged: (mode) =>
                                    setState(() => _mode = mode),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...(_mode == ViewMode.corrections
                        ? List<Widget>.generate(widget.questions.length, (
                            index,
                          ) {
                            final userSelection = widget.selections[index];
                            final isOpen = _expanded.contains(index);
                            return _QuestionResultTile(
                              index: index,
                              isOpen: isOpen,
                              selected: userSelection,
                              question: widget.questions[index],
                              onTap: () => _toggleQuestion(index),
                            );
                          })
                        : [_TopicsBreakdown(stats: _computeTopicStats())]),
                  ],
                ),
              ],
            ),
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
      bottomNavigationBar: Container(
        color: AppColors.primaryGreyLight,
        child: SafeArea(
          child: UnconstrainedBox(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPage(
                        questions: widget.questions, // replay the same quiz
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavyBlue,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Rejouer',
                  style: AppTextStyles.medium15.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int correct;
  final int total;

  const _ScoreCircle({required this.correct, required this.total});

  double get progress => total == 0 ? 0 : correct / total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 70.0,
            width: 70.0,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8.0,
              strokeCap: StrokeCap.round,
              color: AppColors.primaryNavyBlue,
              backgroundColor: AppColors.red,
            ),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(text: '$correct', style: AppTextStyles.bold22),
                TextSpan(text: '/$total', style: AppTextStyles.regular14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionResultTile extends StatelessWidget {
  final int index;
  final bool isOpen;
  final Question question;
  final int selected;
  final VoidCallback onTap;

  const _QuestionResultTile({
    required this.index,
    required this.isOpen,
    required this.question,
    required this.selected,
    required this.onTap,
  });

  bool isCorrect() {
    return selected == question.answer;
  }

  bool isAnswered() {
    return selected != -1;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Card(
        color: AppColors.primaryGreyLight,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10.0),
              onTap: onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _StatusDot(
                          isCorrect: isCorrect(),
                          isAnswered: isAnswered(),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Question ${index + 1}',
                          style: AppTextStyles.regular14,
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primaryNavyBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: QuestionCard(
                    question: question,
                    onSelected: (index) {},
                    selected: selected,
                    showCorrection: true,
                    compact: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isCorrect;
  final bool isAnswered;

  const _StatusDot({required this.isCorrect, required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    final Color bg = isCorrect
        ? AppColors.correctGreen
        : (isAnswered ? AppColors.wrongRed : AppColors.primaryGreyOpacity70);
    final IconData icon = isCorrect ? Icons.check : Icons.close;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: AppColors.white),
    );
  }
}

enum ViewMode { corrections, thematiques }

class _ModeToggle extends StatefulWidget {
  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  State<_ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends State<_ModeToggle> {
  @override
  Widget build(BuildContext context) {
    final bool isCorrections = widget.mode == ViewMode.corrections;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.superSilver,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // Animated moving background
          AnimatedAlign(
            alignment: isCorrections
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
          ),

          // Foreground labels
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      setState(() => widget.onChanged(ViewMode.corrections)),
                  child: Center(
                    child: Text(
                      'Corrections',
                      style: AppTextStyles.bold14.copyWith(
                        color: isCorrections
                            ? AppColors.white
                            : AppColors.primaryGrey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      setState(() => widget.onChanged(ViewMode.thematiques)),
                  child: Center(
                    child: Text(
                      'Thématiques',
                      style: AppTextStyles.bold14.copyWith(
                        color: !isCorrections
                            ? AppColors.white
                            : AppColors.primaryGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicStat {
  final String name;
  int correct = 0;
  int total = 0;

  _TopicStat(this.name);

  double get progress => total == 0 ? 0 : correct / total;
  int get percentage => (progress * 100).round();
}

class _TopicsBreakdown extends StatelessWidget {
  final List<_TopicStat> stats;

  const _TopicsBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Column(
        children: stats.map((s) => _TopicTile(stat: s)).toList(growable: false),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final _TopicStat stat;

  const _TopicTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.name,
                    style: AppTextStyles.regular13,
                    softWrap: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.superSilver),
                  ),
                  child: Text(
                    "${stat.correct}/${stat.total}  •  ${stat.percentage}%",
                    style: AppTextStyles.medium12.copyWith(
                      color:
                          stat.progress >=
                              0.8 // 0.8 is the threshold to pass the exam
                          ? AppColors.correctGreen
                          : (stat.progress >= 0.6
                                ? AppColors.primaryNavyBlue
                                : AppColors.wrongRed),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: stat.progress.clamp(0.01, 1.0),
                minHeight: 8.0,
                backgroundColor: AppColors.superSilver,
                color:
                    stat.progress >=
                        0.8 // 0.8 is the threshold to pass the exam
                    ? AppColors.correctGreen
                    : (stat.progress >= 0.6
                          ? AppColors.primaryNavyBlue
                          : AppColors.wrongRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
