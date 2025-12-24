import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/theme_manager.dart';
import 'package:medical_app/core/utils/app_themes.dart';

class ThemeToggleSwitch extends StatelessWidget {
  final bool compact;
  
  const ThemeToggleSwitch({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    
    if (compact) {
      return Switch(
        value: isDarkMode,
        onChanged: (_) {
          themeManager.toggleTheme();
        },
        activeColor: AppThemes.primaryColor,
      );
    }
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppThemes.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  isDarkMode ? context.tr('dark_mode') : context.tr('light_mode'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Switch(
              value: isDarkMode,
              onChanged: (_) {
                themeManager.toggleTheme();
              },
              activeColor: AppThemes.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
} 