import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:flutter/material.dart';

class QuestionCard extends StatefulWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _selected;

  String _labelFor(int i) => String.fromCharCode(65 + i); // A, B, C, D

  void _toggle(int i) {
    setState(() {
      _selected = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: AppColors.primaryGreyLight),
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
                    q.topic,
                    style: AppTextStyles.regular14.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Question
              Text(q.text, style: AppTextStyles.regular16),
              const SizedBox(height: 16),
              // Choices
              Column(
                children: List.generate(q.choices.length, (i) {
                  final isSelected = _selected == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: () => _toggle(i),
                      style: ElevatedButton.styleFrom(
                        elevation: isSelected ? 0.0 : 1.0,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryNavyBlue
                              : AppColors.transparent,
                          width: 2.0,
                        ),
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryNavyBlue
                                  : AppColors.primaryGreyOpacity70,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Text(
                              _labelFor(i),
                              style: AppTextStyles.medium15.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.choices[i],
                              style: AppTextStyles.regular15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
