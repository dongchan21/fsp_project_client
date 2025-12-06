import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnnualReturnsChart extends StatefulWidget {
  final List<dynamic> annualReturns;

  const AnnualReturnsChart({super.key, required this.annualReturns});

  @override
  State<AnnualReturnsChart> createState() => _AnnualReturnsChartState();
}

class _AnnualReturnsChartState extends State<AnnualReturnsChart> {
  final Color _portfolioColor = const Color(0xFF4E7CFE); // Royal Blue
  final Color _benchmarkColor = const Color(0xFF00BFA5); // Teal/Emerald Green
  
  final Color _barPortfolioColor = const Color(0xFF2962FF); // Deep Blue
  final Color _barBenchmarkColor = const Color(0xFF00E676); // Bright Green

  // [최적화] 계산된 Y축 범위 캐싱
  double _minY = 0;
  double _maxY = 0;

  @override
  void initState() {
    super.initState();
    _calculateYRange();
  }

  @override
  void didUpdateWidget(covariant AnnualReturnsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.annualReturns != oldWidget.annualReturns) {
      _calculateYRange();
    }
  }

  void _calculateYRange() {
    if (widget.annualReturns.isEmpty) {
      _minY = 0;
      _maxY = 0;
      return;
    }

    double maxVal = 0;
    double minVal = 0;
    for (var item in widget.annualReturns) {
      final p = (item['portfolio'] as num).toDouble();
      final b = (item['benchmark'] as num).toDouble();
      maxVal = max(maxVal, p);
      maxVal = max(maxVal, b);
      minVal = min(minVal, p);
      minVal = min(minVal, b);
    }
    _maxY = (maxVal * 1.2).abs();
    _minY = minVal < 0 ? minVal * 1.2 : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.annualReturns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연도별 수익률',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('내 포트폴리오', _barPortfolioColor),
              const SizedBox(width: 16),
              _buildLegendItem('S&P 500', _barBenchmarkColor),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY,
                minY: _minY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey.shade900.withOpacity(0.9),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final year = widget.annualReturns[group.x.toInt()]['year'];
                      final value = rod.toY;
                      final title = rod.color == _barPortfolioColor ? '포트폴리오' : 'S&P 500';
                      return BarTooltipItem(
                        '$year년\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '$title: ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: '${(value * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: rod.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.annualReturns.length) {
                          return const SizedBox.shrink();
                        }
                        final year = widget.annualReturns[index]['year'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.1, // 10%
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.annualReturns.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final portfolioReturn = (data['portfolio'] as num).toDouble();
                  final benchmarkReturn = (data['benchmark'] as num).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: portfolioReturn,
                        color: _barPortfolioColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: benchmarkReturn,
                        color: _barBenchmarkColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(2),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
  
  double max(double a, double b) => a > b ? a : b;
  double min(double a, double b) => a < b ? a : b;
}
