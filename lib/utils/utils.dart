import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/simple_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDuration(Duration d) {
  final formatter = NumberFormat('00');
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) {
    return '${formatter.format(hours)}:${formatter.format(minutes)}:${formatter.format(seconds)}';
  }
  return '${formatter.format(minutes)}:${formatter.format(seconds)}';
}

Color resultBarColor(double score) {
  if (score >= 0.8) return AppColors.correctGreen; // pass threshold
  if (score >= 0.6) return AppColors.primaryNavyBlue;
  return AppColors.wrongRed;
}

Future<T> retryForever<T>(
  Future<T> Function() task, {
  Duration initialDelay = const Duration(milliseconds: 50),
  Duration maxDelay = const Duration(seconds: 1),
}) async {
  var delay = initialDelay;
  while (true) {
    try {
      return await task();
    } catch (_) {
      await Future.delayed(delay);
      final next = Duration(milliseconds: delay.inMilliseconds * 2);
      delay = next > maxDelay ? maxDelay : next;
    }
  }
}

Route<T> centerFadeRoute<T>(
  Widget child, {
  Duration transitionDuration = const Duration(milliseconds: 400),
}) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: transitionDuration,
  reverseTransitionDuration: const Duration(milliseconds: 0),
  transitionsBuilder: (_, animation, __, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);

void yesNoDialog({
  required BuildContext context,
  required String title,
  String? content,
  required Function(BuildContext context) onYesPressed,
  required Function(BuildContext context) onNoPressed,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Center(
        child: Text(
          title,
          style: AppTextStyles.medium16,
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
      // if content is not empty, show it
      content: content != null
          ? Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Text(
                content,
                style: AppTextStyles.regular14,
                textAlign: TextAlign.center,
              ),
            )
          : null,
      actions: [
        DialogButton(
          text: 'Oui',
          color: AppColors.red,
          onPressed: () {
            onYesPressed(context);
          },
        ),
        DialogButton(
          text: 'Non',
          color: AppColors.primaryNavyBlue,
          onPressed: () => {onNoPressed(context)},
        ),
      ],
    ),
  );
}
