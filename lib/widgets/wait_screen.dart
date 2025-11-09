import 'package:flutter/material.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';

class WaitScreen extends StatelessWidget {
  final String imageAsset;
  final String message;
  final double imageSize;
  final double spinnerSize;
  final Widget? bottom; // optional extra (e.g., retry button)

  const WaitScreen({
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

class FutureGate<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final String loadingMessage;
  final String imageAsset;
  final Widget Function(BuildContext, Object error, VoidCallback retry)?
  errorBuilder;

  const FutureGate({
    super.key,
    required this.future,
    required this.builder,
    this.loadingMessage = 'Chargement...',
    this.imageAsset = 'assets/marianne/marianne_waiting.png',
    this.errorBuilder,
  });

  @override
  State<FutureGate<T>> createState() => _FutureGateState<T>();
}

class _FutureGateState<T> extends State<FutureGate<T>> {
  late Future<T> _future;
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
    Future.delayed(const Duration(milliseconds: 150)).then((_) {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  void _retry() {
    setState(() {
      _showLoading = false;
      _future = widget.future; // caller should pass a fresh future if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (!_showLoading) {
            return const SizedBox.shrink();
          }
          return WaitScreen(
            message: widget.loadingMessage,
            imageAsset: widget.imageAsset,
          );
        }
        if (snapshot.hasError) {
          final errBuilder = widget.errorBuilder;
          if (errBuilder != null) {
            return errBuilder(context, snapshot.error!, _retry);
          }
          return WaitScreen(
            message: "Une erreur est survenue.\nAppuyez pour réessayer.",
            imageAsset: widget.imageAsset,
            bottom: ElevatedButton(
              onPressed: _retry,
              child: const Text('Réessayer'),
            ),
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
