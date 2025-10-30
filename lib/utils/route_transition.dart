import 'package:flutter/material.dart';

Route<T> centerFadeScaleRoute<T>(
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
