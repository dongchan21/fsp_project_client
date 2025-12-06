import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import '../widgets/backtest/portfolio_growth_chart.dart';
import '../widgets/backtest/allocation_chart.dart';
import '../widgets/backtest/ai_analysis_tab.dart';
import '../widgets/backtest/annual_returns_chart.dart';

class BacktestResultScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const BacktestResultScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 성장 추이 / 자산 배분 / AI 성과분석
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null)
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back),
                          const SizedBox(width: 8),
                          const Text(
                            '백테스트 결과',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(클릭하여 돌아가기)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                const TabBar(
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
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: Consumer<PortfolioProvider>(
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
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 1) 성장 추이 탭
  // ------------------------------------------------------------
  Widget _buildGrowthTab(dynamic result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PortfolioGrowthChart(result: result),
          AnnualReturnsChart(annualReturns: result.annualReturns),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 2) 자산 배분 탭
  // ------------------------------------------------------------
  Widget _buildAllocationTab(BuildContext context, dynamic result) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: AllocationChart(),
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
