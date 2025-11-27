import 'dart:async';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:flutter/material.dart';

class CountdownScreen extends StatefulWidget {
  final Widget child;
  const CountdownScreen({super.key, required this.child});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int _current = 3;
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;

  final List<Widget> _texts = [
    Text(
      "C'est parti\u00A0!",
      style: AppTextStyles.medium16.copyWith(
        color: AppColors.white,
        fontSize: 30,
      ),
    ),
    Text(
      "1",
      style: AppTextStyles.medium14.copyWith(
        color: AppColors.white,
        fontSize: 150,
      ),
    ),
    Text(
      "2",
      style: AppTextStyles.medium14.copyWith(
        color: AppColors.white,
        fontSize: 150,
      ),
    ),
    Text(
      "3",
      style: AppTextStyles.medium14.copyWith(
        color: AppColors.white,
        fontSize: 150,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scale = Tween<double>(begin: 0.5, end: 1.5).animate(curve);
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(curve);

    // Pop right after the last animation completes (no extra delay)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _current == 0 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.child),
        );
      }
    });

    _start();
  }

  void _start() {
    _playStep();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (_current == 0) {
        t.cancel();
        return;
      }
      setState(() => _current--);
      _playStep();
    });
  }

  void _playStep() => _controller.forward(from: 0.0);

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 0.0,
        ),
        body: Container(
          color: AppColors.primaryNavyBlue,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: _texts[_current],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
