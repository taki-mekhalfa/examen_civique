import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/models/series.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:examen_civique/env/env.dart';

final String _kGoogleFormUrl = Env.googleFormUrl;
final String _kEntryIdQuestionId = Env.entryQuestionId;
final String _kEntryIdComment = Env.entryComment;

void showReportProblemDialog(BuildContext context, Question question) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _ReportProblemDialog(question: question),
  );
}

class _ReportProblemDialog extends StatefulWidget {
  final Question question;

  const _ReportProblemDialog({required this.question});

  @override
  State<_ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<_ReportProblemDialog> {
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_kGoogleFormUrl.isEmpty) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(_kGoogleFormUrl),
            body: {
              _kEntryIdQuestionId: widget.question.id.toString(),
              _kEntryIdComment: text,
            },
          )
          .timeout(const Duration(seconds: 3));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        _showSnackBar(
          message: 'Merci\u00A0!',
          backgroundColor: AppColors.correctGreen,
        );
      } else {
        _showSnackBar(
          message: 'Une erreur est survenue',
          backgroundColor: AppColors.wrongRed,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: 'Une erreur est survenue',
          backgroundColor: AppColors.wrongRed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.regular14.copyWith(color: AppColors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 50, right: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler un problème', style: AppTextStyles.bold16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question #${widget.question.id}',
              style: AppTextStyles.regular12.copyWith(
                color: AppColors.primaryGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Décris le problème ou l\'amélioration suggérée\u00A0:',
              style: AppTextStyles.regular14,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryGrey,
                    width: 2,
                  ),
                ),
                hintText: 'Ton commentaire...',
                hintStyle: AppTextStyles.regular12.copyWith(
                  color: AppColors.hintColor,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: AppTextStyles.medium14.copyWith(color: AppColors.red),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            final isButtonEnabled = value.text.trim().isNotEmpty && !_isLoading;

            return ElevatedButton(
              onPressed: isButtonEnabled ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavyBlue,
                disabledBackgroundColor: AppColors.primaryNavyBlue.withOpacity(
                  0.5,
                ),
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                minimumSize: const Size(100, 36),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Envoyer',
                      style: AppTextStyles.medium14.copyWith(
                        color: AppColors.white,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}
