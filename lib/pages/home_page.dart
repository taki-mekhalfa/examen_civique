import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/quiz_page.dart';
import 'package:examen_civique/repositories/series_repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/count_down_widget.dart';
import 'package:examen_civique/widgets/errors_badge.dart';
import 'package:examen_civique/widgets/home_tile_widget.dart';
import 'package:examen_civique/widgets/wait_screen.dart';
import 'package:flutter/material.dart';

const _examTimeLimit = Duration(minutes: 45);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: _buildAppBar('Mon Examen Civique'),
      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Image(
                image: AssetImage("assets/marianne/marianne_bonjour.png"),
                height: 120.0,
                width: 120.0,
                semanticLabel: 'Illustration Marianne — Bonjour',
              ),
            ),
            HomeTile(
              title: 'Séries simples',
              imagePath: 'assets/images/serie_simple.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeriesListScreen(
                      type: SeriesType.simple,
                      title: 'Séries simples',
                    ),
                  ),
                );
              },
            ),
            HomeTile(
              title: 'Examens blancs',
              imagePath: 'assets/images/examen_blanc.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeriesListScreen(
                      type: SeriesType.exam,
                      title: 'Examens blancs',
                    ),
                  ),
                );
              },
            ),
            HomeTile(
              title: 'Mes erreurs',
              imagePath: 'assets/images/mes_erreurs.png',
              trailing: const ErrorBadge(nbErrors: 0),
              onTap: () {
                _showNoErrorsDialog(context);
              },
            ),
            const HomeTile(
              title: 'Statistiques',
              imagePath: 'assets/images/statistiques.png',
            ),
            const HomeTile(
              title: "L'examen civique ?",
              imagePath: 'assets/images/a_propos.png',
            ),
          ],
        ),
      ),
    );
  }
}

class SeriesListScreen extends StatelessWidget {
  final SeriesType type;
  final String title;

  const SeriesListScreen({super.key, required this.type, required this.title});

  Future<List<SeriesProgress>> _fetchSeries() async {
    final db = await AppDb.instance.database;
    return SeriesRepository(db: db).getSeriesProgressByType(type.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: _buildAppBar(title),
      body: SafeArea(
        child: FutureGate<List<SeriesProgress>>(
          future: _fetchSeries(),
          builder: (context, series) =>
              SeriesList(seriesProgress: series, type: type),
        ),
      ),
    );
  }
}

class SeriesList extends StatelessWidget {
  final List<SeriesProgress> seriesProgress;
  final SeriesType type;

  const SeriesList({
    super.key,
    required this.seriesProgress,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 20.0),
      itemCount: seriesProgress.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Image(
              image: AssetImage("assets/marianne/marianne_series.png"),
              height: 130.0,
              width: 130.0,
              semanticLabel: 'Illustration Marianne — Séries',
            ),
          );
        }

        final series = seriesProgress[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ElevatedButton(
            style: _buttonStyle,
            onPressed: () => _navigateToQuiz(context, series),
            child: Row(
              children: [
                Expanded(child: _SeriesInfo(series: series)),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primaryNavyBlue,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToQuiz(BuildContext context, SeriesProgress series) {
    final quizPage = FutureGate<Series>(
      future: _fetchSeriesQuestions(series.id, series.position),
      builder: (context, series) => QuizPage(
        series: series,
        timeLimit: type == SeriesType.exam ? _examTimeLimit : null,
      ),
    );

    final route = type == SeriesType.exam
        ? centerFadeRoute(CountdownScreen(child: quizPage))
        : MaterialPageRoute(builder: (_) => quizPage);

    Navigator.of(context).push(route);
  }

  Future<Series> _fetchSeriesQuestions(int id, int position) async {
    final db = await AppDb.instance.database;
    final questions = await SeriesRepository(db: db).getSeriesQuestions(id);
    return Series(id: id, position: position, questions: questions);
  }

  static final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.all(10.0),
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    elevation: 1.0,
  );
}

class _SeriesInfo extends StatelessWidget {
  final SeriesProgress series;
  const _SeriesInfo({required this.series});

  @override
  Widget build(BuildContext context) {
    final double? last = series.lastScore;
    final double? best = series.bestScore;
    final double progressValue = last ?? 0.0;
    final bool showBothBadges = last != null && best != null;

    Widget badge(String label, double value) {
      final color = resultBarColor(value);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        margin: const EdgeInsets.only(left: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.superSilver),
        ),
        child: Text(
          '$label • ${(value * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.medium12.copyWith(color: color),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Série ${series.position}', style: AppTextStyles.regular15),
              if (showBothBadges) ...[
                badge('Dernier', last),
                badge('Meilleur', best),
              ],
            ],
          ),
          const SizedBox(height: 6.0),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 8.0,
            borderRadius: BorderRadius.circular(8.0),
            backgroundColor: AppColors.superSilver,
            color: resultBarColor(progressValue),
          ),
        ],
      ),
    );
  }
}

PreferredSizeWidget _buildAppBar(String title) {
  return AppBar(
    elevation: 0.0,
    scrolledUnderElevation: 0,
    toolbarHeight: 50.0,
    title: Text(title, style: AppTextStyles.regular18),
    centerTitle: true,
    actions: [
      IconButton(
        onPressed: () {
          // TODO: open a drawer or menu
        },
        icon: const Icon(Icons.menu),
        color: AppColors.primaryGrey,
        iconSize: 25,
        tooltip: 'Menu',
      ),
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(2.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: _StripedFlag(),
      ),
    ),
  );
}

class _StripedFlag extends StatelessWidget {
  const _StripedFlag();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            height: 10,
            thickness: 10,
            color: AppColors.primaryBlue,
          ),
        ),
        Expanded(
          child: Divider(height: 10, thickness: 10, color: AppColors.white),
        ),
        Expanded(
          child: Divider(height: 10, thickness: 10, color: AppColors.red),
        ),
      ],
    );
  }
}

void _showNoErrorsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Center(
        child: Text(
          "Pas d'erreurs !",
          style: AppTextStyles.medium20,
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: AppColors.primaryGreyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      actionsAlignment: MainAxisAlignment.center,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      content: Container(
        decoration: const BoxDecoration(color: AppColors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tu n'as pas fait d'erreur... Bravo !",
              style: AppTextStyles.regular14,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              "Essaye d'autres modes d'entraînement et reviens plus tard.",
              style: AppTextStyles.regular14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
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
              "J'ai compris",
              style: AppTextStyles.medium16.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ],
    ),
  );
}
