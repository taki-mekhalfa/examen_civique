import 'package:flutter/material.dart';
import 'package:examen_civique/design/style/app_colors.dart';

/// A reusable bottom gradient overlay meant to be placed inside a Stack.
/// By default it matches the current pages' light grey background.
class BottomFade extends StatelessWidget {
  /// Height of the fade overlay.
  final double height;

  /// Base color the fade blends into (usually your page background).
  final Color baseColor;

  /// Optional custom stops for the gradient.
  final List<double> stops;

  const BottomFade({
    super.key,
    this.height = 50.0,
    this.baseColor = AppColors.primaryGreyLight,
    this.stops = const [0.0, 0.75, 1.0],
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: IgnorePointer(
        // lets taps pass through to content underneath
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: stops,
              colors: [
                baseColor.withOpacity(0),
                baseColor.withOpacity(0.78),
                baseColor,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
