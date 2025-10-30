import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/home_tile_item.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/widgets/errors_badge.dart';
import 'package:examen_civique/widgets/question.dart';
import 'package:flutter/material.dart';

List<HomeTileItem> buildHomeMenuItems(BuildContext context, int nbErrors) {
  return [
    HomeTileItem(
      title: 'Séries simples',
      imageAsset: 'assets/images/serie_simple.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Séries simples')),
              body: QuestionCard(
                question: Question(
                  id: 1,
                  text: 'Quelle est la devise de la République française ?',
                  choices: [
                    'Liberté, Égalité, Fraternité',
                    'Unité, Travail, Progrès',
                    'Paix, Justice, Patrie',
                    'Liberté, Égalité, Fraternité, Laïcité',
                  ],
                  answer: 1,
                  explanation:
                      'Inscrite sur les frontons des bâtiments publics.',
                  topic: 'Institutions',
                ),
              ),
            ),
          ),
        );
      },
    ),
    HomeTileItem(
      title: 'Examens blancs',
      imageAsset: 'assets/images/examen_blanc.png',
    ),
    HomeTileItem(
      title: 'Séries thématiques',
      imageAsset: 'assets/images/examen_thematique.png',
    ),
    HomeTileItem(
      title: 'Mes erreurs',
      imageAsset: 'assets/images/mes_erreurs.png',
      trailing: ErrorBadge(nbErrors: nbErrors),
      onTap: () {
        if (nbErrors == 0) {
          _showNoErrorsDialog(context);
        }
      },
    ),
    HomeTileItem(
      title: 'Statistiques',
      imageAsset: 'assets/images/statistiques.png',
    ),
    HomeTileItem(
      title: "L'examen civique ?",
      imageAsset: 'assets/images/a_propos.png',
    ),
  ];
}

void _showNoErrorsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Center(
        child: const Text("Pas d'erreurs !", style: AppTextStyles.medium20),
      ),
      backgroundColor: AppColors.primaryGreyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      actionsAlignment: MainAxisAlignment.center,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      content: Container(
        decoration: BoxDecoration(color: AppColors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              textAlign: TextAlign.center,
              "Tu n'as pas fait d'erreur... Bravo !",
              style: AppTextStyles.regular14,
            ),
            SizedBox(height: 4.0),
            Text(
              textAlign: TextAlign.center,
              "Essaye d'autres modes d'entraînement et reviens plus tard.",
              style: AppTextStyles.regular14,
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
              borderRadius: BorderRadius.circular(10.0),
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
