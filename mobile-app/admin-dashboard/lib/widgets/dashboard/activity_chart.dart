import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/dashboard/domain/entities/dashboard_stats.dart';

class ActivityChart extends StatelessWidget {
  final List<ActivityStats> activityStats;
  final bool isLoading;

  const ActivityChart({
    super.key,
    required this.activityStats,
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
            Text('User Activity', style: theme.textTheme.titleLarge),
            SizedBox(height: 8.h),
            Text(
              'Last 7 days activity statistics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            SizedBox(height: 24.h),
            // Chart
            SizedBox(
              height: 220.h,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface,
                      tooltipRoundedRadius: 8.r,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final data = activityStats[barSpot.x.toInt()];

                          if (barSpot.barIndex == 0) {
                            return LineTooltipItem(
                              'Active: ${data.activeUsers}\n${DateFormat('MMM d').format(data.date)}',
                              TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            );
                          } else {
                            return LineTooltipItem(
                              'Inactive: ${data.inactiveUsers}\n${DateFormat('MMM d').format(data.date)}',
                              TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            );
                          }
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxValue() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerTheme.color,
                        strokeWidth: 1,
                        dashArray: [5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30.h,
                        getTitlesWidget: (value, meta) {
                          final date = activityStats[value.toInt()].date;
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  180,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(180),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: _getMaxValue() * 1.2,
                  lineBarsData: [
                    // Active users line
                    LineChartBarData(
                      spots: _getActiveUsersSpots(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4.r,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withAlpha(25),
                      ),
                    ),
                    // Inactive users line
                    LineChartBarData(
                      spots: _getInactiveUsersSpots(),
                      isCurved: true,
                      color: theme.colorScheme.error,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4.r,
                            color: theme.colorScheme.error,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.error.withAlpha(25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: theme.colorScheme.primary,
                  label: 'Active Users',
                ),
                SizedBox(width: 24.w),
                _LegendItem(
                  color: theme.colorScheme.error,
                  label: 'Inactive Users',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getActiveUsersSpots() {
    return activityStats.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.activeUsers.toDouble());
    }).toList();
  }

  List<FlSpot> _getInactiveUsersSpots() {
    return activityStats.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.inactiveUsers.toDouble());
    }).toList();
  }

  double _getMaxValue() {
    double maxActive = 0;
    double maxInactive = 0;

    for (final stat in activityStats) {
      if (stat.activeUsers > maxActive) {
        maxActive = stat.activeUsers.toDouble();
      }
      if (stat.inactiveUsers > maxInactive) {
        maxInactive = stat.inactiveUsers.toDouble();
      }
    }

    return maxActive > maxInactive ? maxActive : maxInactive;
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}
