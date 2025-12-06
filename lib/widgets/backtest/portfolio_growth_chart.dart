import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PortfolioGrowthChart extends StatefulWidget {
  final dynamic result;

  const PortfolioGrowthChart({super.key, required this.result});

  @override
  State<PortfolioGrowthChart> createState() => _PortfolioGrowthChartState();
}

class _PortfolioGrowthChartState extends State<PortfolioGrowthChart> {
  final List<String> _periods = ['1년', '3년', '5년', 'MAX'];
  String _selectedPeriod = 'MAX';

  // [수정 1] 색상 변경 (시인성 개선)
  final Color _valueColor = const Color(0xFF4E7CFE);     // 평가금액 (Royal Blue)
  final Color _principalColor = const Color(0xFF00BFA5); // 투자원금 (Teal/Emerald Green)
  final Color _benchmarkColor = const Color(0xFFFFAB00); // S&P 500 (Amber)
  final Color _fillGradientStart = const Color(0xFF4E7CFE).withOpacity(0.25);
  final Color _fillGradientEnd = const Color(0xFF4E7CFE).withOpacity(0.0);

  // [최적화] 가공된 전체 데이터 캐싱
  late List<Map<String, dynamic>> _fullProcessedHistory;
  // [최적화] 현재 선택된 기간의 차트 데이터 캐싱
  List<Map<String, dynamic>> _filteredHistory = [];
  double _minY = 0;
  double _maxY = 0;
  double _interval = 1;
  double _xInterval = 1;

  @override
  void initState() {
    super.initState();
    _processData();
    _updateFilteredData();
  }

  @override
  void didUpdateWidget(covariant PortfolioGrowthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result) {
      _processData();
      _updateFilteredData();
    }
  }

  // 1단계: 전체 데이터 전처리 (원금 계산, 벤치마크 매칭) - 데이터 변경 시에만 실행
  void _processData() {
    if (widget.result.history.isEmpty) {
      _fullProcessedHistory = [];
      return;
    }

    final initialCapital = (widget.result.initialCapital as num? ?? 0).toDouble();
    final dcaAmount = (widget.result.dcaAmount as num? ?? 0).toDouble();
    final originalHistory = widget.result.history as List<dynamic>;
    
    final benchmarkData = widget.result.benchmark;
    final List<dynamic> benchmarkHistory = benchmarkData != null 
        ? (benchmarkData['history'] as List<dynamic>) 
        : [];

    _fullProcessedHistory = [];
    for (int i = 0; i < originalHistory.length; i++) {
      final item = originalHistory[i];
      final double principal = initialCapital + (dcaAmount * (i + 1));
      
      double? benchmarkValue;
      if (i < benchmarkHistory.length) {
        benchmarkValue = (benchmarkHistory[i]['value'] as num).toDouble();
      }

      _fullProcessedHistory.add({
        'date': item['date'],
        'value': item['value'],
        'principal': principal,
        'benchmarkValue': benchmarkValue,
      });
    }
  }

  // 2단계: 기간 필터링 및 스케일 계산 - 기간 변경 시에만 실행
  void _updateFilteredData() {
    if (_fullProcessedHistory.isEmpty) {
      _filteredHistory = [];
      return;
    }

    // 기간 필터링
    if (_selectedPeriod == 'MAX') {
      _filteredHistory = _fullProcessedHistory;
    } else {
      final lastDate = DateTime.parse(_fullProcessedHistory.last['date']);
      DateTime startDate;
      switch (_selectedPeriod) {
        case '1년':
          startDate = lastDate.subtract(const Duration(days: 365));
          break;
        case '3년':
          startDate = lastDate.subtract(const Duration(days: 365 * 3));
          break;
        case '5년':
          startDate = lastDate.subtract(const Duration(days: 365 * 5));
          break;
        default:
          startDate = DateTime(2000);
      }
      _filteredHistory = _fullProcessedHistory
          .where((item) => DateTime.parse(item['date']).compareTo(startDate) >= 0)
          .toList();
    }

    if (_filteredHistory.isEmpty) return;

    // Y축 스케일 계산
    final values = _filteredHistory.map((e) => (e['value'] as num).toDouble());
    final principals = _filteredHistory.map((e) => (e['principal'] as num).toDouble());
    final benchmarkValues = _filteredHistory
        .map((e) => e['benchmarkValue'] as double?)
        .where((v) => v != null)
        .map((v) => v!);

    final allValues = [...values, ...principals, ...benchmarkValues];
    if (allValues.isEmpty) return;

    double dataMin = allValues.reduce(min);
    double dataMax = allValues.reduce(max);

    final niceScale = _calculateNiceScale(dataMin, dataMax, 5);
    _minY = niceScale.min;
    _maxY = niceScale.max;
    _interval = niceScale.step;

    final double lastIndex = (_filteredHistory.length - 1).toDouble();
    _xInterval = lastIndex == 0 ? 1 : lastIndex / 4;
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      _updateFilteredData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredHistory.isEmpty) {
      return _buildEmptyState();
    }

    final double lastIndex = (_filteredHistory.length - 1).toDouble();

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 헤더 영역 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '가치 추이',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 5),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade900.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          message: 'S&P 500은 미국 주식시장을 대표하는 지수로, 시장 평균 성과를 나타냅니다.\n내 포트폴리오가 시장 평균보다 얼마나 더 좋은 성과를 냈는지 비교하기 위해 사용합니다.',
                          child: Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(단위: 원)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // 기간 선택 버튼
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return GestureDetector(
                        onTap: () => _onPeriodChanged(period),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4)
                                  ]
                                : [],
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  isSelected ? Colors.black : Colors.grey[500],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // [수정 2] 범례 (Legend) 추가
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendItem('평가금액', _valueColor),
                const SizedBox(width: 12),
                if (_filteredHistory.any((e) => e['benchmarkValue'] != null)) ...[
                  _buildLegendItem('S&P 500', _benchmarkColor),
                  const SizedBox(width: 12),
                ],
                _buildLegendItem('투자원금', _principalColor),
              ],
            ),

            const SizedBox(height: 16),

            // --- 차트 영역 ---
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lastIndex,
                  minY: _minY,
                  maxY: _maxY,

                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 200, 
                    
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Colors.blueGrey.shade900.withOpacity(0.9),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(12),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        bool dateShown = false;
                        
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index < 0 || index >= _filteredHistory.length) return null;

                          final data = _filteredHistory[index];
                          final currencyFormat = NumberFormat('#,###');
                          final principal = (data['principal'] as num).toDouble();
                          
                          String title;
                          Color titleColor;
                          Color valueColor;
                          double value = spot.y;
                          double? returnRate;
                          
                          if (spot.bar.color == _principalColor) {
                            title = '투자원금';
                            titleColor = Colors.white70;
                            valueColor = Colors.white70;
                          } else if (spot.bar.color == _benchmarkColor) {
                            title = 'S&P 500';
                            titleColor = _benchmarkColor;
                            valueColor = _benchmarkColor;
                            if (principal > 0) returnRate = ((value - principal) / principal) * 100;
                          } else {
                            title = '평가금액';
                            titleColor = _valueColor;
                            valueColor = _valueColor;
                            if (principal > 0) returnRate = ((value - principal) / principal) * 100;
                          }

                          final dateStr = data['date'];
                          final dt = DateTime.parse(dateStr);
                          final formattedDate = DateFormat('yyyy.MM.dd').format(dt);

                          final List<TextSpan> children = [
                            TextSpan(
                              text: '$title: ',
                              style: TextStyle(
                                  color: titleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal),
                            ),
                            TextSpan(
                              text: '${currencyFormat.format(value.round())}원',
                              style: TextStyle(
                                  color: valueColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ];

                          if (returnRate != null) {
                            final sign = returnRate >= 0 ? '+' : '';
                            final rateColor = returnRate >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252);
                            children.add(TextSpan(
                              text: ' ($sign${returnRate.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: rateColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ));
                          }
                          children.add(const TextSpan(text: '\n'));

                          if (!dateShown) {
                            dateShown = true;
                            return LineTooltipItem(
                              '$formattedDate\n',
                              const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              children: children,
                            );
                          } else {
                            return LineTooltipItem(
                              '',
                              const TextStyle(fontSize: 0),
                              children: children,
                            );
                          }
                        }).toList();
                      },
                    ),
                  ),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _interval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200],
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: _interval,
                        getTitlesWidget: (value, meta) {
                          if (value == _minY && _minY != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatNiceNumber(value),
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _xInterval == 0 ? 1 : _xInterval,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= _filteredHistory.length) {
                            return const SizedBox.shrink();
                          }
                          String text = '';
                          try {
                            final dateStr = _filteredHistory[idx]['date'];
                            final dt = DateTime.parse(dateStr);
                            text = DateFormat('yy.MM.dd').format(dt);
                          } catch (_) {}
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              text,
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),

                  lineBarsData: [
                    // 1. 원금 그래프
                    LineChartBarData(
                      spots: _filteredHistory.asMap().entries.map((entry) {
                        final val = (entry.value['principal'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), val);
                      }).toList(),
                      isCurved: false,
                      color: _principalColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),

                    // 2. 벤치마크 그래프 (추가)
                    if (_filteredHistory.any((e) => e['benchmarkValue'] != null))
                      LineChartBarData(
                        spots: _filteredHistory.asMap().entries.map((entry) {
                          final val = entry.value['benchmarkValue'] as double? ?? 0.0;
                          return FlSpot(entry.key.toDouble(), val);
                        }).toList(),
                        isCurved: true,
                        color: _benchmarkColor,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),

                    // 3. 평가금액 그래프
                    LineChartBarData(
                      spots: _filteredHistory.asMap().entries.map((entry) {
                        final val = (entry.value['value'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), val);
                      }).toList(),
                      isCurved: true,
                      color: _valueColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_fillGradientStart, _fillGradientEnd],
                        ),
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

  // 범례 아이템 생성 헬퍼
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
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
            color: Colors.black54, 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text('데이터가 없습니다.')),
    );
  }

  _NiceScale _calculateNiceScale(double min, double max, int tickCount) {
    double range = _niceNum(max - min, false);
    double tickSpacing = _niceNum(range / (tickCount - 1), true);
    double niceMin = (min / tickSpacing).floor() * tickSpacing;
    double niceMax = (max / tickSpacing).ceil() * tickSpacing;
    if (niceMax == max) niceMax += tickSpacing;
    if (niceMin == min) niceMin -= tickSpacing;
    return _NiceScale(niceMin, niceMax, tickSpacing);
  }

  double _niceNum(double range, bool round) {
    double exponent = (log(range) / ln10).floorToDouble();
    double fraction = range / pow(10, exponent);
    double niceFraction;
    if (round) {
      if (fraction < 1.5)
        niceFraction = 1;
      else if (fraction < 3)
        niceFraction = 2;
      else if (fraction < 7)
        niceFraction = 5;
      else
        niceFraction = 10;
    } else {
      if (fraction <= 1)
        niceFraction = 1;
      else if (fraction <= 2)
        niceFraction = 2;
      else if (fraction <= 5)
        niceFraction = 5;
      else
        niceFraction = 10;
    }
    return niceFraction * pow(10, exponent);
  }

  String _formatNiceNumber(double value) {
    if (value == 0) return '0';
    final absVal = value.abs();
    if (absVal >= 100000000) {
      final v = value / 100000000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}억';
    }
    if (absVal >= 10000) {
      final v = value / 10000;
      return '${v.toInt()}만';
    }
    return value.toStringAsFixed(0);
  }
}

class _NiceScale {
  final double min;
  final double max;
  final double step;
  _NiceScale(this.min, this.max, this.step);
}
