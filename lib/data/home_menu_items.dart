import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/home_tile_item.dart';
import 'package:examen_civique/models/series.dart';
import 'package:examen_civique/pages/quiz_page.dart';
import 'package:examen_civique/utils/route_transition.dart';
import 'package:examen_civique/widgets/count_down_widget.dart';
import 'package:examen_civique/widgets/errors_badge.dart';
import 'package:flutter/material.dart';

List<HomeTileItem> buildHomeMenuItems(BuildContext context, int nbErrors) {
  final questions = [
    Question(
      id: 1,
      text: 'Quelle est la devise de la République française ?',
      choices: [
        'Liberté, Égalité, Fraternité',
        'Unité, Travail, Progrès',
        'Paix, Justice, Patrie',
        'Force, Honneur, Patrie',
      ],
      answer: 0,
      explanation: '''
La devise **"Liberté, Égalité, Fraternité"** figure à l’article 2 de la Constitution.  
Elle exprime les valeurs fondamentales de la République française.
    ''',
      topic: 'Principes et valeurs',
    ),
    Question(
      id: 2,
      text: 'Qui nomme le Premier ministre en France ?',
      choices: [
        'Le Président de la République',
        'Le Parlement',
        'Le Conseil constitutionnel',
        'Le Conseil des ministres',
      ],
      answer: 0,
      explanation: '''
Selon l’article 8 de la Constitution, **le Président de la République** nomme le Premier ministre,  
chargé de diriger l’action du Gouvernement.
    ''',
      topic: 'Institutions et politique',
    ),
    Question(
      id: 3,
      text: 'Quel est l’un des devoirs essentiels des résidents en France ?',
      choices: [
        'Participer aux élections locales',
        'Respecter les lois de la République',
        'Parler couramment le français',
        'Adhérer à un parti politique',
      ],
      answer: 1,
      explanation: '''
Tout résident en France doit **respecter les lois de la République**,  
principe fondamental du vivre-ensemble en société.
    ''',
      topic: 'Droits et devoirs',
    ),
    Question(
      id: 4,
      text:
          'Quelle période historique marque la fin de la monarchie en France ?',
      choices: [
        'La Révolution française de 1789',
        'La guerre de Cent Ans',
        'La Première Guerre mondiale',
        'La Restauration de 1815',
      ],
      answer: 0,
      explanation: '''
La **Révolution française de 1789** met fin à la monarchie absolue  
et marque la naissance de la République.
    ''',
      topic: 'Histoire et culture',
    ),
    Question(
      id: 5,
      text:
          'Quel document est nécessaire pour travailler légalement en France ?',
      choices: [
        'Un permis de conduire',
        'Une carte de séjour autorisant le travail',
        'Un justificatif de domicile',
        'Une carte Vitale',
      ],
      answer: 1,
      explanation: '''
Pour travailler en France, il faut une **carte de séjour autorisant le travail**,  
preuve du droit de résider et d’exercer une activité professionnelle.
    ''',
      topic: 'Société et vie',
    ),
  ];

  return [
    HomeTileItem(
      title: 'Séries simples',
      imageAsset: 'assets/images/serie_simple.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(questions: questions),
          ),
        );
      },
    ),
    HomeTileItem(
      title: 'Examens blancs',
      imageAsset: 'assets/images/examen_blanc.png',
      onTap: () {
        Navigator.push(
          context,
          centerFadeScaleRoute(
            CountdownScreen(
              child: QuizPage(
                questions: questions,
                timeLimit: Duration(minutes: 1),
              ),
            ),
          ),
        );
      },
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
        child: const Text(
          "Pas d'erreurs !",
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
