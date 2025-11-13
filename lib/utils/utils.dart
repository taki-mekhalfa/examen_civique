import 'package:examen_civique/design/style/app_colors.dart';
import 'package:flutter/material.dart';

Color resultBarColor(double score) {
  if (score >= 0.8) return AppColors.correctGreen; // pass threshold
  if (score >= 0.6) return AppColors.primaryNavyBlue;
  return AppColors.wrongRed;
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
