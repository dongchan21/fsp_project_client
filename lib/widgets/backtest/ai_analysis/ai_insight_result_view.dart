import 'package:flutter/material.dart';
import 'ai_score_card.dart';
import 'ai_info_box.dart';
import 'ai_insight_section.dart';
import 'suggested_portfolio_card.dart';

class AiInsightResultView extends StatelessWidget {
  final Map<String, dynamic> aiInsight;
  final Map<String, dynamic>? score;
  final Function(List<String> symbols, List<double> weights) onApplyPortfolio;

  const AiInsightResultView({
    super.key,
    required this.aiInsight,
    this.score,
    required this.onApplyPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    final summary = aiInsight['summary'] ?? '';
    final evaluation = aiInsight['evaluation'] ?? '';
    final analysis = aiInsight['analysis'] ?? '';
    final suggestion = aiInsight['suggestion'] ?? '';
    final investorType = aiInsight['investorType'] ?? '';

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

        if (score != null) ...[
          AiScoreCard(score: score!),
          const SizedBox(height: 24),
        ],
        
        Row(
          children: [
            Expanded(
              child: AiInfoBox(label: '포트폴리오 성향', value: summary, color: Colors.blue.shade50),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AiInfoBox(label: '추천 투자자 유형', value: investorType, color: Colors.purple.shade50),
            ),
          ],
        ),
        const SizedBox(height: 24),

        AiInsightSection(title: '전반적 평가', content: evaluation),
        const SizedBox(height: 24),
        AiInsightSection(title: '성과 원인 분석', content: analysis),
        const SizedBox(height: 24),
        AiInsightSection(title: '개선 및 보완 제안', content: suggestion),
        
        if (aiInsight['suggestedPortfolio'] != null) ...[
          const SizedBox(height: 40),
          SuggestedPortfolioCard(
            suggestion: aiInsight['suggestedPortfolio'],
            onApply: onApplyPortfolio,
          ),
        ],
      ],
    );
  }
}
