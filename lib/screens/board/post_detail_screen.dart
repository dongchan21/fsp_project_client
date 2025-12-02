import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/board_client_service.dart';
import '../../services/portfolio_provider.dart';
import '../../providers/auth_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Map<String, dynamic>> _postFuture;

  @override
  void initState() {
    super.initState();
    _postFuture = BoardClientService.getPost(widget.postId);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BoardClientService.deletePost(widget.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 삭제되었습니다.')),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?['id'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('포트폴리오 상세', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _postFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final post = snapshot.data!;
                if (currentUserId != null && post['user_id'] == currentUserId) {
                  return IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deletePost,
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('게시글을 찾을 수 없습니다.'));
          }

          final post = snapshot.data!;
          final portfolioData = post['portfolio_data'] as Map<String, dynamic>;
          final date = DateTime.parse(post['created_at']).toLocal();
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);

          // Extract data safely
          final aiScore = portfolioData['aiScore'] as Map<String, dynamic>?;
          final backtestResult = portfolioData['backtestResult'] as Map<String, dynamic>?;
          final aiInsight = portfolioData['aiInsight'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(post['title'], post['author_name'], formattedDate),
                const SizedBox(height: 24),

                // AI Score Card
                if (aiScore != null) ...[
                  _buildAiScoreCard(aiScore),
                  const SizedBox(height: 24),
                ],

                // Backtest Metrics
                if (backtestResult != null) ...[
                  _buildBacktestMetrics(backtestResult),
                  const SizedBox(height: 24),
                ],

                // Portfolio Composition (Chart & List)
                _buildPortfolioSection(portfolioData),
                const SizedBox(height: 24),

                // AI Insight
                if (aiInsight != null) ...[
                  _buildAiInsight(aiInsight),
                  const SizedBox(height: 24),
                ],

                // User Content
                _buildContentSection(post['content']),
                const SizedBox(height: 32),

                // Apply Button
                _buildApplyButton(context, portfolioData),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, String author, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(author[0], style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(author, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildAiScoreCard(Map<String, dynamic> aiScore) {
    final score = aiScore['total'] ?? 0;
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI 포트폴리오 점수', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                '$score점',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ],
          ),
          Icon(Icons.analytics_outlined, size: 60, color: scoreColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildBacktestMetrics(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('백테스트 성과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('총 수익률', '${(result['totalReturn'] * 100).toStringAsFixed(2)}%', Colors.blue),
            _buildMetricCard('CAGR', '${(result['annualizedReturn'] * 100).toStringAsFixed(2)}%', Colors.purple),
            _buildMetricCard('MDD', '${(result['maxDrawdown'] * 100).toStringAsFixed(2)}%', Colors.red),
            _buildMetricCard('Sharpe Ratio', (result['sharpeRatio'] as num).toStringAsFixed(2), Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      width: 160, // Fixed width for better control
      height: 80, // Fixed height to prevent "abnormally large" boxes
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(Map<String, dynamic> data) {
    final symbols = List<String>.from(data['symbols'] ?? []);
    final weights = List<double>.from(data['weights'] ?? []);

    // Generate colors for chart
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('포트폴리오 구성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                // Pie Chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: List.generate(symbols.length, (i) {
                        return PieChartSectionData(
                          color: colors[i % colors.length],
                          value: weights[i],
                          title: '',
                          radius: 40,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend List
                Expanded(
                  child: Column(
                    children: List.generate(symbols.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(symbols[index], style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('${(weights[index] * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsight(Map<String, dynamic> insight) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo[400]),
                const SizedBox(width: 8),
                const Text('AI 투자 인사이트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insight['summary'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
            ),
            if (insight['detailed_analysis'] != null) ...[
              const Divider(height: 24),
              Text(
                insight['detailed_analysis'],
                style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('작성자 코멘트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _applyPortfolio(context, data),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          '내 포트폴리오에 적용하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _applyPortfolio(BuildContext context, Map<String, dynamic> data) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    try {
      final symbols = List<String>.from(data['symbols']);
      final weights = List<double>.from(data['weights']);
      final startDate = DateTime.parse(data['startDate']);
      final endDate = DateTime.parse(data['endDate']);
      final initialCapital = (data['initialCapital'] as num).toDouble();
      final dcaAmount = (data['dcaAmount'] as num).toDouble();
      final useDca = data['useDca'] as bool;

      provider.updateSymbols(symbols);
      provider.updateWeights(weights);
      provider.updateStartDate(startDate);
      provider.updateEndDate(endDate);
      provider.updateInitialCapital(initialCapital);
      provider.updateDcaAmount(dcaAmount);
      provider.toggleUseDca(useDca);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('포트폴리오가 적용되었습니다. 홈 화면에서 확인하세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.popUntil(context, (route) => route.isFirst);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('적용 실패: $e')),
      );
    }
  }
}
