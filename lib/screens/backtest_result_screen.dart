import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';

class BacktestResultScreen extends StatelessWidget {
  const BacktestResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 성장 추이 / 자산 배분 / AI 성과분석
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // 차분한 배경색
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            '백테스트 결과',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: '성장 추이'),
              Tab(text: '자산 배분'),
              Tab(text: 'AI 성과분석'),
            ],
          ),
        ),
        body: Consumer<PortfolioProvider>(
          builder: (context, provider, child) {
            final result = provider.result;
            if (result == null) {
              return const Center(child: Text('결과가 없습니다.'));
            }

            return TabBarView(
              children: [
                _buildGrowthTab(result),
                _buildAllocationTab(context, result),
                _buildAiAnalysisTab(context, provider, result),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 1) 성장 추이 탭
  // ------------------------------------------------------------
  Widget _buildGrowthTab(dynamic result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PortfolioGrowthChart(result: result),
    );
  }

  // ------------------------------------------------------------
  // 2) 자산 배분 탭
  // ------------------------------------------------------------
  Widget _buildAllocationTab(BuildContext context, dynamic result) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);

    final symbols = provider.symbols;
    final weightList = provider.weights;

    if (symbols.isEmpty) {
      return const Center(child: Text("자산 배분 정보가 없습니다."));
    }

    final weights = <String, double>{};
    for (int i = 0; i < symbols.length; i++) {
      weights[symbols[i]] = weightList[i];
    }

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.cyan
    ];

    int idx = 0;
    weights.forEach((symbol, weight) {
      sections.add(
        PieChartSectionData(
          value: weight * 100,
          title: '${(weight * 100).toStringAsFixed(1)}%',
          color: colors[idx % colors.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
      idx++;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '자산 배분',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 4,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: weights.entries.map((e) {
                  final index = weights.keys.toList().indexOf(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[index % colors.length],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${e.key}  •  ${(e.value * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 3) AI 성과분석 탭
  // ------------------------------------------------------------
  Widget _buildAiAnalysisTab(
      BuildContext context, PortfolioProvider provider, dynamic result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(result),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("AI 분석 기능은 작업 중입니다."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'AI 분석 생성',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(dynamic result) {
    final numberFormat = NumberFormat('#,##0.00');
    final percentFormat = NumberFormat('#,##0.00');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '성과 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _row('총 수익률', '${percentFormat.format(result.totalReturn * 100)}%',
                result.totalReturn >= 0 ? Colors.green : Colors.red),
            _row(
                '연 환산 수익률',
                '${percentFormat.format(result.annualizedReturn * 100)}%',
                result.annualizedReturn >= 0 ? Colors.green : Colors.red),
            _row('변동성', '${percentFormat.format(result.volatility * 100)}%',
                Colors.blue),
            _row('샤프 지수', numberFormat.format(result.sharpeRatio), Colors.blue),
            _row('최대 낙폭', '${percentFormat.format(result.maxDrawdown * 100)}%',
                Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// [중요] 아래 클래스는 BacktestResultScreen 클래스 { } 밖(파일의 끝부분)에 위치해야 합니다.
// ============================================================================

class PortfolioGrowthChart extends StatefulWidget {
  final dynamic result;

  const PortfolioGrowthChart({super.key, required this.result});

  @override
  State<PortfolioGrowthChart> createState() => _PortfolioGrowthChartState();
}

class _PortfolioGrowthChartState extends State<PortfolioGrowthChart> {
  final List<String> _periods = ['1년', '3년', '5년', 'MAX'];
  String _selectedPeriod = 'MAX';

  // 색상 정의
  final Color _lineColor = const Color(0xFF4E7CFE); // 평가금액 (Royal Blue)
  final Color _principalColor = const Color(0xFFB0B0C0); // 원금 (회색)
  final Color _fillGradientStart = const Color(0xFF4E7CFE).withOpacity(0.25);
  final Color _fillGradientEnd = const Color(0xFF4E7CFE).withOpacity(0.0);

  @override
  Widget build(BuildContext context) {
    if (widget.result.history.isEmpty) {
      return _buildEmptyState();
    }

    // ----------------------------------------------------------------------
    // [New] 데이터 전처리: history에 principal(원금) 필드가 없으므로 직접 계산해서 추가
    // ----------------------------------------------------------------------
    final initialCapital = (widget.result.initialCapital as num? ?? 0).toDouble();
    final dcaAmount = (widget.result.dcaAmount as num? ?? 0).toDouble();
    final originalHistory = widget.result.history as List<dynamic>;

    // 원금 계산된 새로운 리스트 생성
    final List<Map<String, dynamic>> calculatedHistory = [];
    for (int i = 0; i < originalHistory.length; i++) {
      final item = originalHistory[i];
      // 원금 = 초기투자금 + (월적립금 * (인덱스 + 1))
      // 예: 1개월차(i=0)에는 초기금 + 1회 적립금
      final double principal = initialCapital + (dcaAmount * (i + 1));

      calculatedHistory.add({
        'date': item['date'],
        'value': item['value'],
        'principal': principal, // 계산된 원금 추가
      });
    }

    // 1. 기간 필터링 (계산된 리스트 사용)
    final filteredHistory = _filterHistory(calculatedHistory);
    if (filteredHistory.isEmpty) return _buildEmptyState();

    // 2. 데이터 준비
    final values =
        filteredHistory.map((e) => (e['value'] as num).toDouble()).toList();
    final principals =
        filteredHistory.map((e) => (e['principal'] as num).toDouble()).toList();

    // Y축 범위 계산
    final allValues = [...values, ...principals];

    double dataMin = allValues.reduce((a, b) => min(a, b));
    double dataMax = allValues.reduce((a, b) => max(a, b));

    // Nice Scale 계산
    final niceScale = _calculateNiceScale(dataMin, dataMax, 5);
    final double minY = niceScale.min;
    final double maxY = niceScale.max;
    final double interval = niceScale.step;

    // X축 데이터 포인트
    final double lastIndex = (filteredHistory.length - 1).toDouble();
    final double xInterval =
        lastIndex == 0 ? 1 : (lastIndex / 4).floorToDouble();

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
                    const Text(
                      '가치 추이',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
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
                        onTap: () => setState(() => _selectedPeriod = period),
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
            const SizedBox(height: 32),

            // --- 차트 영역 ---
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lastIndex,
                  minY: minY,
                  maxY: maxY,

                  // 터치(툴팁) 설정
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Colors.blueGrey.shade900.withOpacity(0.9),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(12),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          // 첫 번째 spot(보통 평가금액 라인)에만 툴팁을 띄우고 나머지는 null
                          if (touchedSpots.indexOf(spot) != 0) {
                            return null;
                          }

                          final index = spot.x.toInt();
                          if (index < 0 || index >= filteredHistory.length) {
                            return null;
                          }

                          final data = filteredHistory[index];
                          final principal = (data['principal'] as num).toDouble();
                          final value = (data['value'] as num).toDouble();
                          final profit = value - principal;
                          // 원금이 0이면 수익률 0 처리
                          final returnRate =
                              principal != 0 ? (profit / principal) * 100 : 0.0;

                          final dateStr = data['date'];
                          final dt = DateTime.parse(dateStr);
                          final formattedDate =
                              DateFormat('yyyy.MM.dd').format(dt);
                          final currencyFormat = NumberFormat('#,###');

                          return LineTooltipItem(
                            '$formattedDate\n',
                            const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            children: [
                              const TextSpan(
                                text: '평가금액: ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text:
                                    '${currencyFormat.format(value.round())}원\n',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: '투자원금: ',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text:
                                    '${currencyFormat.format(principal.round())}원\n',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal),
                              ),
                              const TextSpan(
                                text: '수익률: ',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text:
                                    '${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(2)}%',
                                style: TextStyle(
                                    color: returnRate >= 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
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
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == minY && minY != 0) {
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
                        interval: xInterval == 0 ? 1 : xInterval,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= filteredHistory.length) {
                            return const SizedBox.shrink();
                          }
                          String text = '';
                          try {
                            final dateStr = filteredHistory[idx]['date'];
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
                    // 1. 원금 그래프 (회색 점선)
                    LineChartBarData(
                      spots: filteredHistory.asMap().entries.map((entry) {
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

                    // 2. 평가금액 그래프 (메인)
                    LineChartBarData(
                      spots: filteredHistory.asMap().entries.map((entry) {
                        final val = (entry.value['value'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), val);
                      }).toList(),
                      isCurved: true,
                      color: _lineColor,
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

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text('데이터가 없습니다.')),
    );
  }

  List<Map<String, dynamic>> _filterHistory(List<Map<String, dynamic>> fullHistory) {
    if (_selectedPeriod == 'MAX') return fullHistory;
    final lastDate = DateTime.parse(fullHistory.last['date']);
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
        return fullHistory;
    }
    return fullHistory
        .where((item) => DateTime.parse(item['date']).compareTo(startDate) >= 0)
        .toList();
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