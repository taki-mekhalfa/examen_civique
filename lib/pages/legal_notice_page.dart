import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:flutter/material.dart';

class LegalNoticePage extends StatelessWidget {
  const LegalNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: buildAppBar(
        "Conditions d'utilisation",
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryNavyBlue,
          iconSize: 20,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      "assets/marianne/marianne_faq.png",
                      height: 200.0,
                      width: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    "Application non officielle",
                    "Cette application est un outil d'entraînement indépendant et n'est affiliée à aucun organisme gouvernemental.",
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    "Objectif pédagogique",
                    "L'objectif de cette application est d'aider les utilisateurs à préparer leur entretien d'assimilation pour la naturalisation française. Elle propose des quiz et des mises en situation pour s'entraîner.",
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    "Respect du programme officiel",
                    "Le contenu pédagogique (questions, thématiques) a été élaboré dans le respect du décret officiel et du Livret du Citoyen, afin de proposer une expérience proche des conditions réelles de l'examen.",
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    "Limitation de responsabilité",
                    "Bien que nous nous efforcions de maintenir les informations à jour, nous ne pouvons garantir l'exactitude absolue de tout le contenu. Les utilisateurs sont invités à consulter les sources officielles pour toute démarche administrative.",
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    "Confidentialité",
                    "Cette application fonctionne intégralement hors ligne. Aucune connexion internet n'est requise pour son utilisation. Les données saisies, y compris les réponses aux quiz et les statistiques de progression, sont stockées exclusivement sur votre appareil et ne sont jamais transmises à des tiers ni collectées sur des serveurs externes.",
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
            const BottomFade(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryNavyBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bold16.copyWith(
                    color: AppColors.primaryNavyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: AppTextStyles.regular14.copyWith(
                    color: AppColors.primaryGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
