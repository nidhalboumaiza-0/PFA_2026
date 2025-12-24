import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_themes.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';

class ThemeCubitSwitch extends StatelessWidget {
  final bool compact;
  final Color? color;

  const ThemeCubitSwitch({Key? key, this.compact = false, this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        if (state is ThemeLoaded) {
          final isDarkMode = state.themeMode == ThemeMode.dark;

          if (compact) {
            return Switch(
              value: isDarkMode,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
              activeColor: color ?? AppThemes.primaryColor,
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
                        color: color ?? AppThemes.primaryColor,
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
                      context.read<ThemeCubit>().toggleTheme();
                    },
                    activeColor: color ?? AppThemes.primaryColor,
                  ),
                ],
              ),
            ),
          );
        }

        // Show placeholder while theme is initializing
        return const SizedBox.shrink();
      },
    );
  }
}
