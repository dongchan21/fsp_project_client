import 'package:flutter/material.dart';

class SuggestedPortfolioCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final Function(List<String> symbols, List<double> weights) onApply;

  const SuggestedPortfolioCard({
    super.key,
    required this.suggestion,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => onApply(symbols, weights),
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
}
