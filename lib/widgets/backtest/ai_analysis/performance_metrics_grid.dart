import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PerformanceMetricsGrid extends StatelessWidget {
  final dynamic result;

  const PerformanceMetricsGrid({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final percentFormat = NumberFormat('#,##0.0');
    final numberFormat = NumberFormat('#,##0.00');

    final totalReturn = result.totalReturn * 100;
    final annualizedReturn = result.annualizedReturn * 100;
    final mdd = -result.maxDrawdown.abs() * 100;
    final sharpe = result.sharpeRatio;

    // 벤치마크 데이터 처리
    final bm = result.benchmark;
    Map<String, double> bmMetrics = {};

    if (bm != null) {
      // 1. 서버에서 준 값이 있으면 우선 사용
      if (bm['totalReturn'] != null) bmMetrics['totalReturn'] = (bm['totalReturn'] as num).toDouble();
      if (bm['annualizedReturn'] != null) bmMetrics['annualizedReturn'] = (bm['annualizedReturn'] as num).toDouble();
      if (bm['maxDrawdown'] != null) bmMetrics['maxDrawdown'] = -(bm['maxDrawdown'] as num).toDouble().abs();
      if (bm['sharpeRatio'] != null) bmMetrics['sharpeRatio'] = (bm['sharpeRatio'] as num).toDouble();

      // 2. 값이 하나라도 비어있고 history가 있다면 직접 계산해서 채워넣기
      if ((!bmMetrics.containsKey('annualizedReturn') || 
           !bmMetrics.containsKey('maxDrawdown') || 
           !bmMetrics.containsKey('sharpeRatio')) && 
           bm['history'] != null) {
        
        try {
          final history = bm['history'] as List<dynamic>;
          final calculated = _calculateMetrics(history);
          
          if (!bmMetrics.containsKey('totalReturn')) bmMetrics['totalReturn'] = calculated['totalReturn']!;
          if (!bmMetrics.containsKey('annualizedReturn')) bmMetrics['annualizedReturn'] = calculated['annualizedReturn']!;
          if (!bmMetrics.containsKey('maxDrawdown')) bmMetrics['maxDrawdown'] = calculated['maxDrawdown']!;
          if (!bmMetrics.containsKey('sharpeRatio')) bmMetrics['sharpeRatio'] = calculated['sharpeRatio']!;
        } catch (e) {
          debugPrint('Error calculating benchmark metrics: $e');
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성과 지표',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: '총 수익률',
                value: '${totalReturn >= 0 ? '+' : ''}${percentFormat.format(totalReturn)}%',
                valueColor: totalReturn >= 0 ? Colors.green : Colors.red,
                description: '투자 기간 동안의 전체 수익률입니다.',
                myValue: totalReturn,
                benchmarkValue: bmMetrics['totalReturn'] != null 
                    ? bmMetrics['totalReturn']! * 100 
                    : null,
                unit: '%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                label: '연평균 수익률',
                value: '${annualizedReturn >= 0 ? '+' : ''}${percentFormat.format(annualizedReturn)}%',
                valueColor: annualizedReturn >= 0 ? Colors.green : Colors.red,
                description: '투자가 매년 평균적으로 얼마나 성장했는지를 나타냅니다.',
                myValue: annualizedReturn,
                benchmarkValue: bmMetrics['annualizedReturn'] != null 
                    ? bmMetrics['annualizedReturn']! * 100 
                    : null,
                unit: '%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: '최대 낙폭 (MDD)',
                value: '${percentFormat.format(mdd)}%',
                valueColor: Colors.red,
                description: '투자 기간 중 고점 대비 가장 많이 하락한 비율입니다. 위험도를 나타냅니다.',
                myValue: mdd,
                benchmarkValue: bmMetrics['maxDrawdown'] != null 
                    ? bmMetrics['maxDrawdown']! * 100 
                    : null,
                unit: '%',
                higherIsBetter: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                label: '샤프 비율',
                value: numberFormat.format(sharpe),
                valueColor: sharpe >= 1.0
                    ? Colors.green
                    : (sharpe >= 0 ? Colors.blue : Colors.red),
                description: '위험 대비 수익률을 나타냅니다. 높을수록 투자 효율이 좋습니다.',
                myValue: sharpe,
                benchmarkValue: bmMetrics['sharpeRatio'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _calculateMetrics(List<dynamic> history) {
    if (history.isEmpty) return {};

    final firstValue = (history.first['value'] as num).toDouble();
    final lastValue = (history.last['value'] as num).toDouble();

    // 1. Total Return
    final totalReturn = (lastValue - firstValue) / firstValue;

    // 2. Annualized Return (CAGR)
    final startDate = DateTime.parse(history.first['date']);
    final endDate = DateTime.parse(history.last['date']);
    final days = endDate.difference(startDate).inDays;
    
    double annualizedReturn = 0.0;
    if (days > 0 && firstValue > 0 && lastValue > 0) {
      final years = days / 365.0;
      annualizedReturn = pow(lastValue / firstValue, 1 / years) - 1;
    }

    // 3. MDD
    double maxDrawdown = 0.0;
    double peak = firstValue;
    for (var item in history) {
      final value = (item['value'] as num).toDouble();
      if (value > peak) peak = value;
      final drawdown = (value - peak) / peak;
      if (drawdown < maxDrawdown) maxDrawdown = drawdown;
    }

    // 4. Sharpe Ratio
    List<double> returns = [];
    for (int i = 1; i < history.length; i++) {
      final prev = (history[i-1]['value'] as num).toDouble();
      final curr = (history[i]['value'] as num).toDouble();
      if (prev > 0) {
        returns.add((curr - prev) / prev);
      }
    }

    double sharpeRatio = 0.0;
    if (returns.length > 1) {
      final mean = returns.reduce((a, b) => a + b) / returns.length;
      
      // Sample Standard Deviation (N-1)
      final sumSquaredDiff = returns.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b);
      final stdDev = sqrt(sumSquaredDiff / (returns.length - 1));

      if (stdDev > 0) {
        // 데이터 주기에 따른 연율화 계수 적용
        // 평균 간격 계산
        double avgIntervalDays = days / returns.length;
        double annualizationFactor = 252; // 기본값: 일간 (Trading Days)

        if (avgIntervalDays >= 28) {
          annualizationFactor = 12; // 월간
        } else if (avgIntervalDays >= 6) {
          annualizationFactor = 52; // 주간
        }
        
        sharpeRatio = (mean / stdDev) * sqrt(annualizationFactor);
      }
    }

    return {
      'totalReturn': totalReturn,
      'annualizedReturn': annualizedReturn,
      'maxDrawdown': maxDrawdown,
      'sharpeRatio': sharpeRatio,
    };
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color valueColor,
    required String description,
    double? myValue,
    double? benchmarkValue,
    String unit = '',
    bool higherIsBetter = true,
  }) {
    InlineSpan tooltipContent;
    
    if (myValue != null && benchmarkValue != null) {
      final diff = myValue - benchmarkValue;
      final diffStr = NumberFormat('#,##0.0').format(diff.abs());
      final bmStr = NumberFormat('#,##0.0').format(benchmarkValue);
      
      String status;
      if (diff > 0) status = '높습니다';
      else if (diff < 0) status = '낮습니다';
      else status = '같습니다';

      // 더 좋은지 판단 (higherIsBetter가 true면 높을수록 좋음, false면 낮을수록 좋음)
      bool isBetter = higherIsBetter ? (diff > 0) : (diff < 0);
      if (diff == 0) isBetter = true; // 같으면 긍정적으로 표시

      final color = isBetter ? const Color(0xFF00E676) : const Color(0xFFFF5252); // 밝은 녹색 / 밝은 빨강 (다크 툴팁 배경용)

      tooltipContent = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
        children: [
          TextSpan(text: description),
          const TextSpan(text: '\n\n[S&P 500 대비]\n', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '$bmStr$unit 보다 '),
          TextSpan(
            text: '$diffStr$unit $status',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      tooltipContent = TextSpan(
        text: description,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Tooltip(
                richMessage: tooltipContent,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.help_outline, size: 16, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
