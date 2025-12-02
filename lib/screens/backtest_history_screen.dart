import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BacktestHistoryScreen extends StatefulWidget {
  const BacktestHistoryScreen({super.key});

  @override
  State<BacktestHistoryScreen> createState() => _BacktestHistoryScreenState();
}

class _BacktestHistoryScreenState extends State<BacktestHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getBacktestHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 백테스트 히스토리'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('저장된 히스토리가 없습니다.'));
          }

          final history = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = history[index];
              final symbols = List<String>.from(item['symbols']);
              final weights = List<dynamic>.from(item['weights']);
              final summary = item['resultSummary'];
              final date = DateTime.parse(item['createdAt']).toLocal();
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);

              // 포트폴리오 구성 문자열
              final portfolioStr = List.generate(symbols.length, (i) {
                return '${symbols[i]} ${(weights[i] * 100).toStringAsFixed(0)}%';
              }).join(', ');

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              portfolioStr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '기간: ${item['startDate']} ~ ${item['endDate']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric('CAGR', summary['annualizedReturn'], Colors.purple),
                          _buildMetric('MDD', summary['maxDrawdown'], Colors.red),
                          _buildMetric('Sharpe', summary['sharpeRatio'], Colors.teal),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, dynamic value, Color color) {
    String valueStr;
    if (label == 'Sharpe') {
      valueStr = (value as num).toStringAsFixed(2);
    } else {
      valueStr = '${((value as num) * 100).toStringAsFixed(2)}%';
    }

    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          valueStr,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
