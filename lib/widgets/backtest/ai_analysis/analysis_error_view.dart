import 'package:flutter/material.dart';

class AnalysisErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const AnalysisErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text("오류 발생: $error"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("재시도"),
          ),
        ],
      ),
    );
  }
}
