import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/portfolio_provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../screens/board/create_post_screen.dart';
import '../../screens/login_screen.dart';
import 'ai_analysis/performance_metrics_grid.dart';
import 'ai_analysis/analysis_loading_view.dart';
import 'ai_analysis/analysis_error_view.dart';
import 'ai_analysis/ai_insight_result_view.dart';
import 'ai_analysis/generate_analysis_button.dart';

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
          PerformanceMetricsGrid(result: widget.result),

          const SizedBox(height: 40),

          // 2. AI 분석 결과 또는 버튼
          if (_isLoading)
            const AnalysisLoadingView()
          else if (_error != null)
            AnalysisErrorView(
              error: _error!,
              onRetry: _generateInsight,
            )
          else if (_aiInsight != null) ...[
            AiInsightResultView(
              aiInsight: _aiInsight!,
              score: _score,
              onApplyPortfolio: _applyAndRunBacktest,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (!authProvider.isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('로그인이 필요한 서비스입니다.')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(
                        backtestResult: widget.result,
                        aiScore: _score,
                        aiInsight: _aiInsight,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('포트폴리오 공유하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else
            GenerateAnalysisButton(onPressed: _generateInsight),
        ],
      ),
    );
  }



  void _applyAndRunBacktest(List<String> symbols, List<double> weights) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // 1. 포트폴리오 업데이트
    provider.updateSymbols(symbols);
    provider.updateWeights(weights);
    
    // 2. 백테스트 실행
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
}


