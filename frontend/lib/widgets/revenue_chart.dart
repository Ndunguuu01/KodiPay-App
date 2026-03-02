import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RevenueChart extends StatelessWidget {
  final Map<String, dynamic> insights;

  const RevenueChart({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final monthlyRevenue = (insights['monthlyRevenue'] as num).toDouble();
    // Mock data for other months to make it look realistic for demo
    // In production, this should come from historical data API
    final List<double> revenueData = [
      monthlyRevenue * 0.8,
      monthlyRevenue * 0.9,
      monthlyRevenue * 0.85,
      monthlyRevenue * 1.1,
      monthlyRevenue * 0.95,
      monthlyRevenue,
    ];

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 4,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: monthlyRevenue * 1.5,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppConstants.primaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'KES ${rod.toY.toInt()}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
                        const titles = [
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec'
                        ];
                        if (value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              titles[value.toInt()],
                              style: const TextStyle(
                                color: Color(0xff7589a2),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  checkToShowHorizontalLine: (value) =>
                      value % (monthlyRevenue / 2) == 0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xffe7e8ec),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: revenueData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        gradient: const LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            Color(0xFF3949AB), // Lighter shade
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: monthlyRevenue * 1.5,
                          color: const Color(0xfff3f3f3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
