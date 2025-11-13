import 'package:flutter/material.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';

class MarianneWaitingScreen extends StatelessWidget {
  final String imageAsset;
  final String message;
  final double imageSize;
  final double spinnerSize;
  final Widget? bottom; // optional extra (e.g., retry button)

  const MarianneWaitingScreen({
    super.key,
    this.imageAsset = 'assets/marianne/marianne_waiting.png',
    this.message = 'Initialisation en cours...',
    this.imageSize = 200,
    this.spinnerSize = 50,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreyLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imageAsset, width: imageSize, height: imageSize),
            const SizedBox(height: 24),
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(
                color: AppColors.primaryGrey,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.regular18,
              textAlign: TextAlign.center,
            ),
            if (bottom != null) ...[const SizedBox(height: 16), bottom!],
          ],
        ),
      ),
    );
  }
}

class DialogScreenLoader extends StatelessWidget {
  final String message;
  const DialogScreenLoader({super.key, this.message = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.primaryGreyLight.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryNavyBlue),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.medium16.copyWith(
                  color: AppColors.primaryNavyBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
