import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:flutter/material.dart';

class ErrorBadge extends StatelessWidget {
  const ErrorBadge({super.key, required this.nbErrors});

  final int nbErrors;

  @override
  Widget build(BuildContext context) {
    if (nbErrors == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        '$nbErrors',
        style: AppTextStyles.medium16.copyWith(color: AppColors.brilliantWhite),
      ),
    );
  }
}
