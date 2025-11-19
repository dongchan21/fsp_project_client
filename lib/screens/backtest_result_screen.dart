import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';

class BacktestResultScreen extends StatelessWidget {
  const BacktestResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백테스트 결과'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final result = provider.result;
          if (result == null) {
            return const Center(child: Text('결과가 없습니다'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(context, result),
                const SizedBox(height: 16),
                _buildChartCard(context, result),
                const SizedBox(height: 16),
                _buildMetricsCard(context, result),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic result) {
    final numberFormat = NumberFormat('#,##0.00');
    final percentFormat = NumberFormat('#,##0.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성과 요약',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              '총 수익률',
              '${percentFormat.format(result.totalReturn * 100)}%',
              result.totalReturn >= 0 ? Colors.green : Colors.red,
            ),
            const Divider(),
            _buildSummaryRow(
              '연 환산 수익률',
              '${percentFormat.format(result.annualizedReturn * 100)}%',
              result.annualizedReturn >= 0 ? Colors.green : Colors.red,
            ),
            const Divider(),
            _buildSummaryRow(
              '변동성',
              '${percentFormat.format(result.volatility * 100)}%',
              Colors.blue,
            ),
            const Divider(),
            _buildSummaryRow(
              '샤프 지수',
              numberFormat.format(result.sharpeRatio),
              Colors.blue,
            ),
            const Divider(),
            _buildSummaryRow(
              '최대 낙폭',
              '${percentFormat.format(result.maxDrawdown * 100)}%',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, dynamic result) {
    if (result.history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('히스토리 데이터가 없습니다'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '포트폴리오 가치 추이',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final isNeg = value < 0;
                          final formatted = NumberFormat.compactCurrency(locale: 'ko_KR', symbol: '₩').format(value.abs());
                          return Text(
                            isNeg ? '-$formatted' : formatted,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: result.history.length / 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < result.history.length) {
                            final date = result.history[value.toInt()]['date'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                date.toString().split('T')[0],
                                style: const TextStyle(fontSize: 8),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: result.history
                          .asMap()
                          .entries
                          .map<FlSpot>((entry) {
                        final value = (entry.value['value'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context, dynamic result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '추가 지표',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터 포인트 수: ${result.history.length}',
              style: const TextStyle(fontSize: 14),
            ),
            if (result.history.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '시작일: ${result.history.first['date']}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '종료일: ${result.history.last['date']}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
