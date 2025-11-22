import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/errors_quiz_page.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:flutter/material.dart';

class ErrorsPage extends StatelessWidget {
  final int nbErrors;

  const ErrorsPage({super.key, required this.nbErrors});

  Future<void> _clearWrongQuestions(BuildContext context) async {
    final db = await AppDb.instance.database;
    await Repository(db: db).clearWrongQuestions();
  }

  Future<void> _handleResetCounter(BuildContext context) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogScreenLoader(),
    );

    final navigator = Navigator.of(context);
    await retryForever(() => _clearWrongQuestions(context));

    if (!navigator.mounted) return;

    navigator.pop(); // close loader
    navigator.pop(); // close dialog
    navigator.pop(); // exit errors page
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: buildAppBar('Mes erreurs'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: _ContentCard(
                            nbErrors: nbErrors,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => {
                            yesNoDialog(
                              context: context,
                              title:
                                  'Souhaites-tu réinitialiser ton compteur ?',
                              content:
                                  'Ton compteur d\'erreurs sera remis à zéro.',
                              onYesPressed: (context) =>
                                  _handleResetCounter(context),
                              onNoPressed: (context) => Navigator.pop(context),
                            ),
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavyBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                          child: Text(
                            'Réinitialiser mon compteur',
                            style: AppTextStyles.medium16.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.nbErrors, required this.colorScheme});

  final int nbErrors;
  final ColorScheme colorScheme;

  Future<List<Question>> _getWrongQuestions() async {
    final db = await AppDb.instance.database;
    return Repository(db: db).getWrongQuestions();
  }

  Future<void> _handleStartQuiz(BuildContext context) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogScreenLoader(),
    );

    final navigator = Navigator.of(context);

    final wrongQuestions = await retryForever(() => _getWrongQuestions());

    if (!navigator.mounted) return;

    navigator.pop();

    final errorsPage = ErrorsQuiz(questions: wrongQuestions);

    navigator.pushReplacement(MaterialPageRoute(builder: (_) => errorsPage));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  child: const Image(
                    image: AssetImage("assets/marianne/marianne_loupe.png"),
                    height: 130,
                    width: 130,
                    semanticLabel: 'Illustration Marianne — Séries',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nous avons rassemblé les questions que tu as ratées pour t’aider à les corriger.'
                  '\n\nChaque réponse revue te rapproche un peu plus de la réussite !',
                  style: AppTextStyles.regular16,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'À corriger: ',
                        style: AppTextStyles.regular16,
                      ),
                      TextSpan(
                        text: '$nbErrors ',
                        style: AppTextStyles.medium17.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Prêt·e à relever le défi ?',
                  style: AppTextStyles.regular16,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleStartQuiz(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavyBlue,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16), // controls overall size
                    elevation: 4, // adds shadow
                    shadowColor: Colors.black.withAlpha(100),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoMoreErrorsPage extends StatelessWidget {
  const NoMoreErrorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Mes erreurs'),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("assets/marianne/marianne_confetti.png"),
                    height: 250,
                    width: 250,
                    semanticLabel: 'Illustration Marianne — Séries',
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    'Félicitations !',
                    style: AppTextStyles.medium30.copyWith(
                      color: AppColors.primaryNavyBlue,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tu as corrigé toutes les erreurs !',
                    style: AppTextStyles.regular16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
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
                  style: AppTextStyles.medium16.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
