import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int? selected;
  final ValueChanged<int> onSelected;
  final bool showCorrection;
  final bool compact;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onSelected,
    this.selected,
    this.showCorrection = false,
    this.compact = false,
  });

  String _labelFor(int i) => String.fromCharCode(65 + i); // A, B, C, D

  bool isSelected(int i) {
    return selected == i;
  }

  Color tileBorderColor(int i) {
    if (!showCorrection) {
      return isSelected(i) ? AppColors.primaryNavyBlue : AppColors.transparent;
    }

    if (question.isCorrect(i)) return AppColors.correctGreen;
    if (isSelected(i)) return AppColors.wrongRed;
    return AppColors.transparent;
  }

  Color badgeColor(int i) {
    if (!showCorrection) {
      return isSelected(i)
          ? AppColors.primaryNavyBlue
          : AppColors.primaryGreyOpacity70;
    }

    if (question.isCorrect(i)) return AppColors.correctGreen;
    if (isSelected(i)) return AppColors.wrongRed;
    return AppColors.primaryGreyOpacity70;
  }

  Color tileBackgroundColor(int i) {
    if (!showCorrection) {
      return AppColors.white;
    }

    if (question.isCorrect(i)) return AppColors.softGreen;
    if (isSelected(i)) return AppColors.softRed;
    return AppColors.white;
  }

  Icon? icon(int i) {
    if (!showCorrection || (!question.isCorrect(i) && !isSelected(i))) {
      return null;
    }

    if (question.isCorrect(i)) {
      return const Icon(Icons.check, size: 18, color: AppColors.correctGreen);
    }

    return const Icon(Icons.close, size: 18, color: AppColors.wrongRed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.transparent),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavyBlue,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    question.topic,
                    style: AppTextStyles.regular13.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
              // Question
              Text(
                question.text,
                style: compact
                    ? AppTextStyles.regular14
                    : AppTextStyles.regular16,
              ),
              const SizedBox(height: 16.0),
              // Choices
              Column(
                children: List.generate(question.choices.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: () => onSelected(i),
                      style: ElevatedButton.styleFrom(
                        elevation: isSelected(i) ? 0.0 : 1.0,
                        side: BorderSide(color: tileBorderColor(i), width: 2.0),
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        backgroundColor: tileBackgroundColor(i),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: compact ? 22 : 35,
                            height: compact ? 22 : 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeColor(i),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Text(
                              _labelFor(i),
                              style: AppTextStyles.medium12.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question.choices[i],
                              style: compact
                                  ? AppTextStyles.regular12
                                  : AppTextStyles.regular14,
                            ),
                          ),
                          icon(i) ?? const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              if (showCorrection) ...[
                const SizedBox(height: 16.0),
                MarkdownBody(
                  data: question.explanation,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTextStyles.regular14,
                    strong: AppTextStyles.bold14,
                    em: AppTextStyles.mediumItalic14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
