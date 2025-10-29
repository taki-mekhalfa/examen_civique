import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:flutter/material.dart';

class HomeTile extends StatelessWidget {
  const HomeTile({
    super.key,
    required this.title,
    required this.imagePath,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String imagePath;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
      child: ElevatedButton(
        onPressed: () => onTap?.call(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          padding: EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            top: 10.0,
            bottom: 10.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 1.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(imagePath, height: 55.0, width: 55.0),
                SizedBox(width: 16.0),
                Text(title, style: AppTextStyles.regular18),
              ],
            ),
            Row(
              children: [
                trailing ?? const SizedBox.shrink(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
