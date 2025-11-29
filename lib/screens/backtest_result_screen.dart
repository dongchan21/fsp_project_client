import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';
import '../services/api_service.dart';

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
    return AiAnalysisTab(provider: provider, result: result);
  }
}

class AiAnalysisTab extends StatefulWidget {
  final PortfolioProvider provider;
  final dynamic result;

  const AiAnalysisTab({
    super.key,
    required this.provider,
    required this.result,
  });

  @override
  State<AiAnalysisTab> createState() => _AiAnalysisTabState();
}

class _AiAnalysisTabState extends State<AiAnalysisTab> {
  bool _isLoading = false;
  Map<String, dynamic>? _aiInsight;
  Map<String, dynamic>? _score;
  String? _error;

  Future<void> _generateInsight() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. 성과 지표 요약 데이터 준비
      final summary = {
        'totalReturn': widget.result.totalReturn,
        'annualizedReturn': widget.result.annualizedReturn,
        'volatility': widget.result.volatility,
        'sharpeRatio': widget.result.sharpeRatio,
        'maxDrawdown': widget.result.maxDrawdown,
        // 필요한 경우 추가 필드 (예: annualReturn 등 서버가 기대하는 키 이름 확인 필요)
        // 서버의 insight_service.dart는 'annualReturn', 'totalReturn', 'mdd', 'sharpe'를 사용함
        'annualReturn': widget.result.annualizedReturn,
        'mdd': widget.result.maxDrawdown,
        'sharpe': widget.result.sharpeRatio,
      };

      // 2. 서버에 분석 요청 (점수 및 텍스트 생성)
      final analysisResult = await ApiService.analyzeInsight(summary: summary);
      
      if (analysisResult.containsKey('error')) {
        throw Exception(analysisResult['error']);
      }

      final score = analysisResult['score'];
      final analysis = analysisResult['analysis'];

      // 3. AI 인사이트 생성 요청
      final portfolio = {
        'symbols': widget.provider.symbols,
        'weights': widget.provider.weights,
      };

      final response = await ApiService.generateAiInsight(
        score: score,
        analysis: analysis,
        portfolio: portfolio,
      );

      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
      } else {
        setState(() {
          _aiInsight = response['aiInsight'];
          _score = score;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 성과 지표
          _buildPerformanceMetrics(widget.result),

          const SizedBox(height: 40),

          // 2. AI 분석 결과 또는 버튼
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF4E7CFE)),
                  SizedBox(height: 16),
                  Text("AI가 포트폴리오를 분석 중입니다...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("오류 발생: $_error"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generateInsight,
                    child: const Text("재시도"),
                  ),
                ],
              ),
            )
          else if (_aiInsight != null)
            _buildInsightResult()
          else
            _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _generateInsight,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4E7CFE), // 차트 색상과 통일
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: const Color(0xFF4E7CFE).withOpacity(0.4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 20),
          SizedBox(width: 8),
          Text(
            'AI 분석 생성',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightResult() {
    final summary = _aiInsight?['summary'] ?? '';
    final evaluation = _aiInsight?['evaluation'] ?? '';
    final analysis = _aiInsight?['analysis'] ?? '';
    final suggestion = _aiInsight?['suggestion'] ?? '';
    final investorType = _aiInsight?['investorType'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF4E7CFE)),
            SizedBox(width: 8),
            Text(
              'AI 분석 결과',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_score != null) ...[
          _buildScoreCard(_score!),
          const SizedBox(height: 24),
        ],
        
        // 요약 & 투자자 유형
        Row(
          children: [
            Expanded(
              child: _buildInfoBox('포트폴리오 성향', summary, Colors.blue.shade50),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoBox('추천 투자자 유형', investorType, Colors.purple.shade50),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSection('전반적 평가', evaluation),
        const SizedBox(height: 24),
        _buildSection('성과 원인 분석', analysis),
        const SizedBox(height: 24),
        _buildSection('개선 및 보완 제안', suggestion),
        
        if (_aiInsight?['suggestedPortfolio'] != null) ...[
          const SizedBox(height: 40),
          _buildSuggestedPortfolioSection(_aiInsight!['suggestedPortfolio']),
        ],
      ],
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> score) {
    final total = score['total'] ?? 0;
    final grade = score['grade'] ?? 'N/A';
    final profit = score['profit'] ?? 0;
    final risk = score['risk'] ?? 0;
    final efficiency = score['efficiency'] ?? 0;

    Color gradeColor;
    if (grade == 'A') {
      gradeColor = Colors.green;
    } else if (grade == 'B') {
      gradeColor = Colors.blue;
    } else if (grade == 'C') {
      gradeColor = Colors.orange;
    } else {
      gradeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '포트폴리오 종합 점수',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '/ 100',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor, width: 2),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildScoreBar('수익성', profit, 30, Colors.redAccent),
          const SizedBox(height: 16),
          _buildScoreBar('리스크 관리', risk, 35, Colors.blueAccent),
          const SizedBox(height: 16),
          _buildScoreBar('효율성', efficiency, 35, Colors.green),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int value, int max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444),
              ),
            ),
            Text(
              '$value / $max',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / max,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedPortfolioSection(Map<String, dynamic> suggestion) {
    List<String> symbols = [];
    List<double> weights = [];
    String reason = suggestion['reason'] ?? '';

    try {
      symbols = List<String>.from(suggestion['symbols']);
      weights = List<double>.from(suggestion['weights'].map((x) => (x as num).toDouble()));
    } catch (e) {
      return const SizedBox.shrink(); // 데이터 파싱 실패 시 숨김
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart_outline, color: Color(0xFF4E7CFE)),
            SizedBox(width: 8),
            Text(
              'AI 제안 포트폴리오',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.indigo.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              // 종목 비중 리스트
              ...List.generate(symbols.length, (index) {
                final weightPercent = (weights[index] * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4E7CFE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            symbols[index],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$weightPercent%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _applyAndRunBacktest(symbols, weights),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E7CFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '이 포트폴리오로 백테스트 실행',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyAndRunBacktest(List<String> symbols, List<double> weights) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // 1. 포트폴리오 업데이트
    provider.updateSymbols(symbols);
    provider.updateWeights(weights);
    
    // 2. 백테스트 실행
    // 로딩 표시를 위해 다이얼로그를 띄우거나 할 수 있지만, 
    // 여기서는 탭 이동 후 Provider의 isLoading 상태를 보여주는 방식을 사용
    
    // 탭 이동 (성장 추이 탭으로)
    DefaultTabController.of(context).animateTo(0);
    
    // 백테스트 실행
    provider.runBacktest().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 제안 포트폴리오가 적용되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF444444),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(dynamic result) {
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

  // [수정 1] 색상 변경 (시인성 개선)
  final Color _valueColor = const Color(0xFF4E7CFE);     // 평가금액 (Royal Blue)
  final Color _principalColor = const Color(0xFF00BFA5); // 투자원금 (Teal/Emerald Green)
  final Color _benchmarkColor = const Color(0xFFFFAB00); // S&P 500 (Amber)
  final Color _fillGradientStart = const Color(0xFF4E7CFE).withOpacity(0.25);
  final Color _fillGradientEnd = const Color(0xFF4E7CFE).withOpacity(0.0);

  @override
  Widget build(BuildContext context) {
    if (widget.result.history.isEmpty) {
      return _buildEmptyState();
    }

    // 데이터 전처리 (원금 계산 및 벤치마크 준비)
    final initialCapital = (widget.result.initialCapital as num? ?? 0).toDouble();
    final dcaAmount = (widget.result.dcaAmount as num? ?? 0).toDouble();
    final originalHistory = widget.result.history as List<dynamic>;
    
    // 벤치마크 데이터
    final benchmarkData = widget.result.benchmark;
    final List<dynamic> benchmarkHistory = benchmarkData != null 
        ? (benchmarkData['history'] as List<dynamic>) 
        : [];

    final List<Map<String, dynamic>> calculatedHistory = [];
    for (int i = 0; i < originalHistory.length; i++) {
      final item = originalHistory[i];
      final double principal = initialCapital + (dcaAmount * (i + 1));
      
      // 벤치마크 값 (인덱스 매칭)
      double? benchmarkValue;
      if (i < benchmarkHistory.length) {
        benchmarkValue = (benchmarkHistory[i]['value'] as num).toDouble();
      }

      calculatedHistory.add({
        'date': item['date'],
        'value': item['value'],
        'principal': principal,
        'benchmarkValue': benchmarkValue,
      });
    }

    // 1. 기간 필터링
    final filteredHistory = _filterHistory(calculatedHistory);
    if (filteredHistory.isEmpty) return _buildEmptyState();

    // 2. 데이터 준비
    final values =
        filteredHistory.map((e) => (e['value'] as num).toDouble()).toList();
    final principals =
        filteredHistory.map((e) => (e['principal'] as num).toDouble()).toList();
    final benchmarkValues = filteredHistory
        .map((e) => e['benchmarkValue'] as double?)
        .where((v) => v != null)
        .map((v) => v!)
        .toList();

    // Y축 범위 계산
    final allValues = [...values, ...principals, ...benchmarkValues];
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
        lastIndex == 0 ? 1 : lastIndex / 4;

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
            
            const SizedBox(height: 16),
            
            // [수정 2] 범례 (Legend) 추가
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendItem('평가금액', _valueColor),
                const SizedBox(width: 12),
                if (benchmarkValues.isNotEmpty) ...[
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
                  minY: minY,
                  maxY: maxY,

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
                          if (index < 0 || index >= filteredHistory.length) return null;

                          final data = filteredHistory[index];
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
                    // 1. 원금 그래프
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

                    // 2. 벤치마크 그래프 (추가)
                    if (benchmarkValues.isNotEmpty)
                      LineChartBarData(
                        spots: filteredHistory.asMap().entries.map((entry) {
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
                      spots: filteredHistory.asMap().entries.map((entry) {
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