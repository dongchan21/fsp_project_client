import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/board_client_service.dart';
import '../../services/portfolio_provider.dart';
import '../../models/portfolio.dart';

class CreatePostScreen extends StatefulWidget {
  final BacktestResult? backtestResult;
  final Map<String, dynamic>? aiScore;
  final Map<String, dynamic>? aiInsight;

  const CreatePostScreen({
    super.key, 
    this.backtestResult,
    this.aiScore,
    this.aiInsight,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.backtestResult != null) {
      _titleController.text = '내 포트폴리오 백테스트 결과 공유합니다';
      _contentController.text = '백테스트 결과가 좋아서 공유합니다. 한번 봐주세요!';
      
      if (widget.aiScore != null) {
        _contentController.text += '\n\nAI 점수: ${widget.aiScore!['total']}점';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('공유될 포트폴리오 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('종목: ${portfolioProvider.symbols.join(", ")}'),
                    Text('비중: ${portfolioProvider.weights.map((w) => "${(w * 100).toStringAsFixed(0)}%").join(", ")}'),
                    if (widget.backtestResult != null) ...[
                      const Divider(),
                      const Text('백테스트 결과 요약:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('총 수익률: ${(widget.backtestResult!.totalReturn * 100).toStringAsFixed(2)}%'),
                      Text('연평균 수익률 (CAGR): ${(widget.backtestResult!.annualizedReturn * 100).toStringAsFixed(2)}%'),
                      Text('MDD: ${(widget.backtestResult!.maxDrawdown * 100).toStringAsFixed(2)}%'),
                      Text('Sharpe Ratio: ${widget.backtestResult!.sharpeRatio.toStringAsFixed(2)}'),
                    ],
                    if (widget.aiScore != null) ...[
                      const Divider(),
                      const Text('AI 분석 결과:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('AI 점수: ${widget.aiScore!['total']}점'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final portfolioData = {
                      'symbols': portfolioProvider.symbols,
                      'weights': portfolioProvider.weights,
                      'startDate': portfolioProvider.startDate.toIso8601String(),
                      'endDate': portfolioProvider.endDate.toIso8601String(),
                      'initialCapital': portfolioProvider.initialCapital,
                      'dcaAmount': portfolioProvider.dcaAmount,
                      'useDca': portfolioProvider.useDca,
                      if (widget.backtestResult != null)
                        'backtestResult': widget.backtestResult!.toJson(),
                      if (widget.aiScore != null)
                        'aiScore': widget.aiScore,
                      if (widget.aiInsight != null)
                        'aiInsight': widget.aiInsight,
                    };

                    await BoardClientService.createPost(
                      _titleController.text,
                      _contentController.text,
                      portfolioData,
                    );

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('작성 실패: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
