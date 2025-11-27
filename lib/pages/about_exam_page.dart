import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/home_page.dart'; // For buildAppBar
import 'package:examen_civique/widgets/bottom_fade.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutExamPage extends StatelessWidget {
  const AboutExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      appBar: buildAppBar(
        "L'examen civique\u00A0?",
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: AppColors.primaryGrey,
          iconSize: 25,
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            children: [
              const SizedBox(height: 20),
              // --- Hero Section (The "Why") ---
              Center(
                child: Image.asset(
                  "assets/marianne/marianne_penser.png",
                  height: 200.0,
                  width: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "L'étape clé de ton intégration.",
                textAlign: TextAlign.center,
                style: AppTextStyles.medium20.copyWith(
                  color: AppColors.primaryNavyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "L'examen civique est obligatoire pour obtenir la nationalité française ou une carte de résident. Voici tout ce que tu dois savoir.",
                textAlign: TextAlign.center,
                style: AppTextStyles.regular16.copyWith(
                  color: AppColors.primaryGrey,
                ),
              ),
              const SizedBox(height: 24),
              // --- Key Stats Cards ---
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: "Questions",
                      value: "40",
                      icon: Icons.help_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoCard(
                      label: "Durée",
                      value: "45 min",
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoCard(
                      label: "Réussite",
                      value: "32/40",
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Section: Who is it for? ---
              _SectionHeader(title: "Qui est concerné\u00A0?"),
              Card(
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _CheckRow(text: "Demande de naturalisation"),
                      const Divider(height: 20, thickness: 2.0),
                      _CheckRow(text: "Carte de résident (10 ans)"),
                      const Divider(height: 20, thickness: 2.0),
                      _CheckRow(text: "Carte de séjour pluriannuelle"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Section: Content Source ---
              _SectionHeader(title: "Une préparation fiable"),
              Card(
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text.rich(
                    TextSpan(
                      text: "Tous nos ",
                      style: AppTextStyles.regular14.copyWith(height: 1.5),
                      children: [
                        TextSpan(text: "QCM", style: AppTextStyles.bold14),
                        const TextSpan(text: " et "),
                        TextSpan(
                          text: "questions de mise en situation",
                          style: AppTextStyles.bold14,
                        ),
                        const TextSpan(text: " sont fondés sur le "),
                        TextSpan(
                          text: "Livret du citoyen",
                          style: AppTextStyles.bold14.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const TextSpan(text: ", les "),
                        TextSpan(
                          text: "réformes récentes",
                          style: AppTextStyles.bold14,
                        ),
                        const TextSpan(text: " et les "),
                        TextSpan(
                          text: "retours d’expérience des candidats",
                          style: AppTextStyles.bold14,
                        ),
                        const TextSpan(
                          text:
                              ", afin d’offrir une préparation complète et réaliste.",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Section: The Programme (Detailed breakdown) ---
              _SectionHeader(title: "Le programme officiel"),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(
                    "https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052381620",
                  ),
                ),
                child: Text(
                  "Consulter le décret officiel",
                  style: AppTextStyles.medium14.copyWith(
                    color: AppColors.primaryNavyBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: "L'examen comporte ",
                  style: AppTextStyles.regular14.copyWith(
                    color: AppColors.primaryGrey,
                  ),
                  children: [
                    TextSpan(
                      text: "40",
                      style: AppTextStyles.bold14.copyWith(
                        color: AppColors.primaryGrey,
                      ),
                    ),
                    const TextSpan(text: " questions réparties en "),
                    TextSpan(
                      text: "5",
                      style: AppTextStyles.bold14.copyWith(
                        color: AppColors.primaryGrey,
                      ),
                    ),
                    const TextSpan(text: " thématiques précises\u00A0:"),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _ThemeCard(
                title: "Principes et valeurs",
                count: 11,
                subtopics: const [
                  "Devise et symboles de la République\u00A0: 3 questions",
                  "Laïcité\u00A0: 2 questions",
                  "Mises en situation\u00A0: 6 questions",
                ],
              ),
              _ThemeCard(
                title: "Institutions et politique",
                count: 6,
                subtopics: const [
                  "Démocratie et droit de vote\u00A0: 3 questions",
                  "Organisation de la République française\u00A0: 2 questions",
                  "Institutions européennes\u00A0: 1 question",
                ],
              ),
              _ThemeCard(
                title: "Droits et devoirs",
                count: 11,
                subtopics: const [
                  "Droits fondamentaux\u00A0: 2 questions",
                  "Obligations et devoirs des personnes résidant en France\u00A0: 3 questions",
                  "Mises en situation\u00A0: 6 questions",
                ],
              ),
              _ThemeCard(
                title: "Histoire et culture",
                count: 8,
                subtopics: const [
                  "Principales périodes et personnages historiques\u00A0: 3 questions",
                  "Territoires et géographie\u00A0: 3 questions",
                  "Patrimoine français\u00A0: 2 questions",
                ],
              ),
              _ThemeCard(
                title: "Société et vie",
                count: 4,
                subtopics: const [
                  "S’installer et résider en France\u00A0: 1 question",
                  "L’accès aux soins\u00A0: 1 question",
                  "Travailler en France\u00A0: 1 question",
                  "Autorité parentale et système éducatif\u00A0: 1 question",
                ],
              ),

              const SizedBox(height: 24),

              // --- Section: Rules ---
              _SectionHeader(title: "Les règles de l'examen"),
              Card(
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RuleRow(
                        icon: Icons.computer_rounded,
                        title: "Support numérique",
                        desc:
                            "L'épreuve se passe sur une tablette ou un ordinateur.",
                      ),
                      const SizedBox(height: 16),
                      _RuleRow(
                        icon: Icons.exposure_plus_1_rounded,
                        title: "Notation",
                        desc:
                            "1 point par bonne réponse. 0 point par erreur. Pas de points négatifs.",
                      ),
                      const SizedBox(height: 16),
                      _RuleRow(
                        icon: Icons.badge_rounded,
                        title: "Identité",
                        desc:
                            "Pièce d'identité ou titre de séjour obligatoire le jour J.",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- CTA ---
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Commencer l'entraînement",
                    style: AppTextStyles.medium16.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
          const BottomFade(),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: AppTextStyles.bold16.copyWith(color: AppColors.black),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryNavyBlue, size: 25),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.medium18.copyWith(
              color: AppColors.primaryNavyBlue,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.medium14.copyWith(
              color: AppColors.primaryNavyBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColors.correctGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.regular14)),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final int count;
  final List<String> subtopics;

  const _ThemeCard({
    required this.title,
    required this.count,
    required this.subtopics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                height: double.infinity,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title, style: AppTextStyles.bold14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreyLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.superSilver),
                          ),
                          child: Text(
                            "$count questions",
                            style: AppTextStyles.bold14.copyWith(
                              color: AppColors.primaryGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...subtopics.map(
                      (subtopic) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "• ",
                              style: TextStyle(color: AppColors.grey425),
                            ),
                            Expanded(
                              child: Text(
                                subtopic,
                                style: AppTextStyles.regular12.copyWith(
                                  color: AppColors.grey425,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _RuleRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.primaryNavyBlue, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bold14),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.regular13.copyWith(
                  color: AppColors.primaryGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
