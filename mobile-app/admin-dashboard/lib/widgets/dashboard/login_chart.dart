import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/dashboard/domain/entities/dashboard_stats.dart';

class LoginChart extends StatelessWidget {
  final List<LoginStats> loginStats;
  final bool isLoading;

  const LoginChart({
    super.key,
    required this.loginStats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        height: 250.h,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Login Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Last 7 days login/logout statistics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24.h),
            // Chart
            SizedBox(
              height: 220.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface,
                      tooltipRoundedRadius: 8.r,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = loginStats[group.x].date;
                        final value =
                            rodIndex == 0
                                ? loginStats[group.x].logins
                                : loginStats[group.x].logouts;
                        final type = rodIndex == 0 ? 'Logins' : 'Logouts';
                        return BarTooltipItem(
                          '$type: $value\n${DateFormat('MMM d').format(date)}',
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = loginStats[value.toInt()].date;
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30.h,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.7,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          );
                        },
                        reservedSize: 30.w,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _getMaxValue() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerTheme.color,
                        strokeWidth: 1,
                        dashArray: [5],
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  barGroups:
                      loginStats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data.logins.toDouble(),
                              color: theme.colorScheme.primary,
                              width: 16.w,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.r),
                                topRight: Radius.circular(4.r),
                              ),
                            ),
                            BarChartRodData(
                              toY: data.logouts.toDouble(),
                              color: theme.colorScheme.error,
                              width: 16.w,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.r),
                                topRight: Radius.circular(4.r),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: theme.colorScheme.primary, label: 'Logins'),
                SizedBox(width: 24.w),
                _LegendItem(color: theme.colorScheme.error, label: 'Logouts'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxValue() {
    double maxLogins = 0;
    double maxLogouts = 0;

    for (final stat in loginStats) {
      if (stat.logins > maxLogins) {
        maxLogins = stat.logins.toDouble();
      }
      if (stat.logouts > maxLogouts) {
        maxLogouts = stat.logouts.toDouble();
      }
    }

    return maxLogins > maxLogouts ? maxLogins : maxLogouts;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
