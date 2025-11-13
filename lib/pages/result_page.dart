import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:flutter/material.dart';

enum ViewMode { corrections, thematiques }

class ResultPage extends StatefulWidget {
  final Series series;
  final List<Question> questions;
  final List<int> selections;
  final int correctCount;
  final Duration duration;

  ResultPage({
    super.key,
    required this.series,
    required this.selections,
    required this.duration,
  }) : questions = series.questions,
       correctCount = selections.indexed
           .where((e) => series.questions[e.$1].answer == e.$2)
           .length;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  // ===== UI Constants
  static const _cardHPad = EdgeInsets.symmetric(horizontal: 10.0);
  static const _pagePad = EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0);
  static const _toolbarHeight = 50.0;

  // ===== State
  final Set<int> _expanded = <int>{};
  ViewMode _mode = ViewMode.corrections;

  // ===== Derived
  double get _scorePct => widget.questions.isEmpty
      ? 0
      : (widget.correctCount / widget.questions.length) * 100.0;

  String get _scoreMarianne {
    if (_scorePct >= 80) return 'assets/marianne/marianne_bravo.png';
    if (_scorePct >= 60) return 'assets/marianne/marianne_bien_joue.png';
    if (_scorePct >= 40) return 'assets/marianne/marianne_pas_mal.png';
    return 'assets/marianne/marianne_courage.png';
  }

  List<_TopicStat> _computeTopicStats() {
    final map = <String, _TopicStat>{};

    for (var i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final sel = widget.selections[i];
      final stat = map.putIfAbsent(q.topic, () => _TopicStat(q.topic));
      stat.total++;
      if (sel == q.answer) stat.correct++;
    }

    final stats = map.values.toList()
      ..sort((a, b) => a.progress.compareTo(b.progress)); // weakest first
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
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: _toolbarHeight,
        centerTitle: true,
        title: Text(
          'Série ${widget.series.id} - Résultats',
          style: AppTextStyles.regular18,
        ),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(_scoreMarianne, height: 120.0, width: 300.0),
                  ],
                ),
                Padding(
                  padding: _cardHPad,
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
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Accède au détail des questions pour vérifier tes réponses.',
                                  style: AppTextStyles.regular14.copyWith(
                                    color: AppColors.primaryGrey,
                                  ),
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
                            onChanged: (m) => setState(() => _mode = m),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_mode == ViewMode.corrections)
                  ...List<Widget>.generate(widget.questions.length, (index) {
                    final isOpen = _expanded.contains(index);
                    return _QuestionResultTile(
                      index: index,
                      isOpen: isOpen,
                      question: widget.questions[index],
                      selected: widget.selections[index],
                      onTap: () => _toggleQuestion(index),
                    );
                  })
                else
                  _TopicsBreakdown(stats: _computeTopicStats()),
                const SizedBox(height: 64),
              ],
            ),
          ),
          const BottomFade(),
        ],
      ),
      // bottomNavigationBar: _ReplayBar(
      //   onReplay: () {
      //     Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //         builder: (_) => QuizPage(
      //           questions: widget.questions, // replay same quiz
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int correct;
  final int total;
  const _ScoreCircle({required this.correct, required this.total});

  double get _progress => total == 0 ? 0 : correct / total;

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
              value: _progress,
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

  bool get _isAnswered => selected != -1;

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
                          isCorrect: question.isCorrect(selected),
                          isAnswered: _isAnswered,
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
                    onSelected: (_) {},
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
      padding: _ResultPageState._pagePad,
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
    final barColor = resultBarColor(stat.progress);
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
                    '${stat.correct}/${stat.total}  •  ${stat.percentage}%',
                    style: AppTextStyles.medium12.copyWith(color: barColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: stat.progress.clamp(0.01, 1.0),
                minHeight: 8.0,
                backgroundColor: AppColors.superSilver,
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
