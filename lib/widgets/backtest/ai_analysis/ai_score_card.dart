import 'package:flutter/material.dart';

class AiScoreCard extends StatelessWidget {
  final Map<String, dynamic> score;

  const AiScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
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
}
