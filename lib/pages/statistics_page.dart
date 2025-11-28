import 'dart:math';
import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ViewMode { week, month }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  ViewMode _viewMode = ViewMode.week;
  late final Future<Statistics> _weekStatistics;
  late final Future<Statistics> _monthStatistics;

  Future<Statistics> _getStatistics(DateTime from, DateTime to) async {
    final db = await AppDb.instance.database;
    return Repository(db: db).getStatistics(from, to);
  }

  get _monday {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
  }

  get _month {
    return DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void initState() {
    super.initState();
    final nextSunday = _monday.add(const Duration(days: 6));
    _weekStatistics = retryForever(() => _getStatistics(_monday, nextSunday));

    final lastDayOfMonth = DateTime(_month.year, _month.month + 1, 0);
    _monthStatistics = retryForever(
      () => _getStatistics(_month, lastDayOfMonth),
    );
  }

  String _fmtWeek(DateTime monday) {
    final DateFormat formatter = DateFormat('d MMMM', 'fr_FR');
    final sunday = monday.add(const Duration(days: 6));
    return '${formatter.format(monday)} – ${formatter.format(sunday)}';
  }

  String _fmtMonth(DateTime month) {
    final DateFormat formatter = DateFormat('MMMM yyyy', 'fr_FR');
    return formatter.format(month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: buildAppBar(
        'Statistiques',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: AppColors.primaryGrey,
          iconSize: 25,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2.0,
              child: _ModeToggle(
                mode: _viewMode,
                onChanged: (m) => setState(() => _viewMode = m),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            decoration: BoxDecoration(
              color: AppColors.primaryGreyLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavyBlue,
                  blurRadius: 0.0,
                  offset: const Offset(0, 4.0),
                ),
              ],
            ),
            child: Text(
              _viewMode == ViewMode.week
                  ? _fmtWeek(_monday)
                  : _fmtMonth(_month),
              style: AppTextStyles.regular16,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: _viewMode == ViewMode.week
                ? _weekStatistics
                : _monthStatistics,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return FutureBuilder(
                  future: Future.delayed(const Duration(milliseconds: 150)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    return const Expanded(child: DialogScreenLoader());
                  },
                );
              }
              final isThereActivity = (snapshot.data?.answeredCount ?? 0) > 0;
              if (!isThereActivity) {
                return _NoActivityWidget(mode: _viewMode);
              }
              return StatsOverviewPage(mode: _viewMode, stats: snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}

class _NoActivityWidget extends StatelessWidget {
  final ViewMode mode;
  const _NoActivityWidget({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/marianne/marianne_pas_de_pratique.png',
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 32.0),
          mode == ViewMode.week
              ? Text(
                  'Aucune activité cette semaine.',
                  style: AppTextStyles.regular16,
                )
              : Text(
                  'Aucune activité ce mois-ci.',
                  style: AppTextStyles.regular16,
                ),
          const SizedBox(height: 16.0),
          Text(
            'Tu peux commencer à pratiquer en allant sur la page d’accueil.',
            style: AppTextStyles.regular16,
            textAlign: TextAlign.center,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavyBlue,
                elevation: 0.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              child: Text(
                'Revenir au menu',
                style: AppTextStyles.medium16.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
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
    final bool isweek = widget.mode == ViewMode.week;

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
            alignment: isweek ? Alignment.centerLeft : Alignment.centerRight,
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
                  onTap: () => setState(() => widget.onChanged(ViewMode.week)),
                  child: Center(
                    child: Text(
                      'Cette semaine',
                      style: AppTextStyles.bold14.copyWith(
                        color: isweek ? AppColors.white : AppColors.primaryGrey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => widget.onChanged(ViewMode.month)),
                  child: Center(
                    child: Text(
                      'Ce mois-ci',
                      style: AppTextStyles.bold14.copyWith(
                        color: !isweek
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

class StatsOverviewPage extends StatelessWidget {
  final ViewMode mode;
  final Statistics stats;
  const StatsOverviewPage({super.key, required this.mode, required this.stats});

  static const _hPad = EdgeInsets.symmetric(horizontal: 10.0);

  @override
  Widget build(BuildContext context) {
    final answered = stats.answeredCount;
    final correct = stats.correctCount;
    final scorePct = stats.correctPercentage;

    return Expanded(
      child: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: _hPad,
                child: Row(
                  children: [
                    Expanded(child: _KpiTimeCard(duration: stats.timeSpent)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiScoreCard(
                        answered: answered,
                        correct: correct,
                        pct: scorePct,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: _hPad,
                child: _TopicsCard(topics: stats.topics),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: _hPad,
                child: mode == ViewMode.week
                    ? _WeekSeriesCard(
                        simpleSeries: stats.simpleSeries,
                        mockExams: stats.mockExams,
                      )
                    : _MonthSeriesCard(
                        simpleSeries: stats.simpleSeries,
                        mockExams: stats.mockExams,
                      ),
              ),
            ],
          ),
          const BottomFade(),
        ],
      ),
    );
  }
}

class _KpiTimeCard extends StatelessWidget {
  final Duration duration;
  const _KpiTimeCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: AppColors.primaryNavyBlue,
              size: 25,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temps passé', style: AppTextStyles.medium13),
                  const SizedBox(height: 2.0),
                  Text(
                    formatDuration(duration, long: true),
                    style: AppTextStyles.medium16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiScoreCard extends StatelessWidget {
  final int answered;
  final int correct;
  final double pct;

  const _KpiScoreCard({
    required this.answered,
    required this.correct,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final color = resultBarColor(pct);

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questions répondues', style: AppTextStyles.medium13),
            const SizedBox(height: 2.0),
            Text('$answered', style: AppTextStyles.medium16),
            const SizedBox(height: 2.0),
            Text(
              '${(pct * 100).round()}% correctes',
              style: AppTextStyles.medium13.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  final Map<String, TopicStatistics> topics;
  const _TopicsCard({required this.topics});

  @override
  Widget build(BuildContext context) {
    final entries = topics.entries.toList()
      ..sort((a, b) => a.value.progress.compareTo(b.value.progress));

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Maîtrise par thématique', style: AppTextStyles.bold16),
              ],
            ),
            const SizedBox(height: 8),
            ...entries.map((e) => _TopicRow(name: e.key, stat: e.value)),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String name;
  final TopicStatistics stat;
  const _TopicRow({required this.name, required this.stat});

  @override
  Widget build(BuildContext context) {
    final barColor = resultBarColor(stat.progress);

    return Card(
      color: AppColors.white,
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
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

class _WeekSeriesCard extends StatefulWidget {
  final List<double?> simpleSeries;
  final List<double?> mockExams;

  const _WeekSeriesCard({required this.simpleSeries, required this.mockExams});

  @override
  State<_WeekSeriesCard> createState() => _WeekSeriesCardState();
}

class _WeekSeriesCardState extends State<_WeekSeriesCard> {
  // Track the indices of the touched group and the specific rod (bar)
  int _touchedGroupIndex = -1;
  int _touchedRodIndex = -1;

  List<BarChartGroupData> _getGroups() {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < 7; i++) {
      double? simpleVal;
      if (i < widget.simpleSeries.length && widget.simpleSeries[i] != null) {
        simpleVal = (widget.simpleSeries[i]! * 40).floorToDouble();
      }

      double? mockVal;
      if (i < widget.mockExams.length && widget.mockExams[i] != null) {
        mockVal = (widget.mockExams[i]! * 40).floorToDouble();
      }

      final isGroupTouched = _touchedGroupIndex == i;

      // Boolean helpers to check which specific rod is touched
      final isSimpleTouched = isGroupTouched && _touchedRodIndex == 0;
      final isMockTouched = isGroupTouched && _touchedRodIndex == 1;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: simpleVal ?? 0,
              color: AppColors.grey425,
              width: isSimpleTouched ? 16 : 12,
              borderRadius: BorderRadius.circular(isSimpleTouched ? 4 : 2),
            ),
            BarChartRodData(
              toY: mockVal ?? 0,
              color: AppColors.primaryNavyBlue,
              width: isMockTouched ? 16 : 12,
              borderRadius: BorderRadius.circular(isMockTouched ? 4 : 2),
              borderSide: BorderSide.none,
            ),
          ],
        ),
      );
    }
    return groups;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.0,
          height: 5.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.regular13),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [Text('Score par jour', style: AppTextStyles.bold18)],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.5,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                child: BarChart(
                  BarChartData(
                    maxY: 41.0,
                    minY: 0.0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: 1,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.primaryGrey,
                          width: 2.0,
                        ),
                        left: BorderSide(
                          color: AppColors.primaryGrey,
                          width: 2.0,
                        ),
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 36.0,
                          getTitlesWidget: (value, meta) {
                            const weekDays = [
                              'Lun',
                              'Mar',
                              'Mer',
                              'Jeu',
                              'Ven',
                              'Sam',
                              'Dim',
                            ];
                            if (value < 0 || value > 6) {
                              return const SizedBox.shrink();
                            }
                            final i = value.toInt();
                            return SideTitleWidget(
                              meta: meta,
                              space: 6.0,
                              angle: -1.0,
                              child: Text(
                                weekDays[i],
                                style: AppTextStyles.medium12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          reservedSize: 30.0,
                          getTitlesWidget: (value, meta) {
                            if (value > 40) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                style: AppTextStyles.medium12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // --- NEW TOUCH LOGIC ---
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primaryNavyBlue,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        tooltipMargin: 8,
                        tooltipBorderRadius: BorderRadius.circular(8.0),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}/40',
                            AppTextStyles.bold14.copyWith(
                              color: AppColors.white,
                            ),
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          setState(() {
                            _touchedGroupIndex = -1;
                            _touchedRodIndex = -1;
                          });
                          return;
                        }
                        setState(() {
                          _touchedGroupIndex =
                              barTouchResponse.spot!.touchedBarGroupIndex;
                          _touchedRodIndex =
                              barTouchResponse.spot!.touchedRodDataIndex;
                        });
                      },
                    ),

                    // -----------------------
                    rangeAnnotations: RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: 32.0,
                          y2: 40.0,
                          color: AppColors.softGreen,
                        ),
                        HorizontalRangeAnnotation(
                          y1: 24.0,
                          y2: 32.0,
                          color: AppColors.softOrange,
                        ),
                      ],
                    ),
                    extraLinesData: ExtraLinesData(
                      extraLinesOnTop: false,
                      horizontalLines: [
                        HorizontalLine(
                          y: 32.0,
                          color: AppColors.correctGreen,
                          dashArray: [8, 5],
                          strokeWidth: 0.5,
                        ),
                        HorizontalLine(
                          y: 24.0,
                          color: AppColors.orange,
                          dashArray: [8, 5],
                          strokeWidth: 0.5,
                        ),
                      ],
                    ),
                    barGroups:
                        _getGroups(), // Now calls the method with highlight logic
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(AppColors.grey425, 'Séries simples'),
                const SizedBox(width: 10),
                _buildLegendItem(AppColors.primaryNavyBlue, 'Examens blancs'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSeriesCard extends StatelessWidget {
  final List<double?> simpleSeries;
  final List<double?> mockExams;

  const _MonthSeriesCard({required this.simpleSeries, required this.mockExams});

  List<FlSpot> _getSpots(List<double?> series) {
    if (series.every((e) => e == null)) return [];

    return series.indexed.map((spot) {
      final (index, value) = spot;
      if (value == null) return FlSpot.nullSpot;
      final double score = (value * 40).floorToDouble();
      return FlSpot(index.toDouble(), score);
    }).toList();
  }

  double? _getMonthMaxX() {
    final lastIndexSimple = simpleSeries.lastIndexWhere((e) => e != null);
    final lastIndexMock = mockExams.lastIndexWhere((e) => e != null);

    if (lastIndexSimple == -1 && lastIndexMock == -1) {
      return simpleSeries.length.toDouble();
    }
    return max(lastIndexSimple, lastIndexMock) + 1 + 0.1;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.0,
          height: 5.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.regular13),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [Text('Score par jour', style: AppTextStyles.bold18)],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.5,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                child: LineChart(
                  LineChartData(
                    maxY: 41.0,
                    minY: 0.0,
                    maxX: _getMonthMaxX(),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.primaryGrey,
                          width: 2.0,
                        ),
                        left: BorderSide(
                          color: AppColors.primaryGrey,
                          width: 2.0,
                        ),
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36.0,
                          getTitlesWidget: (value, meta) {
                            value = value + 1;
                            if (value < 0 ||
                                value > (_getMonthMaxX() ?? 24_10_1996)) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                style: AppTextStyles.medium12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          reservedSize: 30.0,
                          getTitlesWidget: (value, meta) {
                            if (value > 40) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                style: AppTextStyles.medium12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    rangeAnnotations: RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: 32.0,
                          y2: 40.0,
                          color: AppColors.softGreen,
                        ),
                        HorizontalRangeAnnotation(
                          y1: 24.0,
                          y2: 32.0,
                          color: AppColors.softOrange,
                        ),
                      ],
                    ),
                    extraLinesData: ExtraLinesData(
                      extraLinesOnTop: false,
                      horizontalLines: [
                        HorizontalLine(
                          y: 32.0,
                          dashArray: [8, 5],
                          strokeWidth: 0.5,
                          color: AppColors.correctGreen,
                        ),
                        HorizontalLine(
                          y: 24.0,
                          dashArray: [8, 5],
                          strokeWidth: 0.5,
                          color: AppColors.orange,
                        ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        curveSmoothness: 0.5,
                        color: AppColors.grey425,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        spots: _getSpots(simpleSeries),
                      ),
                      LineChartBarData(
                        curveSmoothness: 0.5,
                        color: AppColors.primaryNavyBlue,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        spots: _getSpots(mockExams),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(AppColors.grey425, 'Séries simples'),
                const SizedBox(width: 10),
                _buildLegendItem(AppColors.primaryNavyBlue, 'Examens blancs'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
