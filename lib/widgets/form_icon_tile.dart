import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Reusable rounded icon tile used as the prefixIcon on form fields
/// across Device Registration, User Registration, and Login screens.
/// One shared definition, so changing the style/size/color later
/// only needs a change in this one file.
class FormIconTile extends StatelessWidget {
  final String assetPath;
  const FormIconTile(this.assetPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
        color: AppColors.primaryDark,
      ),
    );
  }
}