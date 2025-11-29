import 'package:flutter/material.dart';

class AnalysisLoadingView extends StatelessWidget {
  const AnalysisLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF4E7CFE)),
          SizedBox(height: 16),
          Text("AI가 포트폴리오를 분석 중입니다...",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
