import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import '../widgets/backtest/portfolio_growth_chart.dart';
import '../widgets/backtest/allocation_chart.dart';
import '../widgets/backtest/ai_analysis_tab.dart';

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
