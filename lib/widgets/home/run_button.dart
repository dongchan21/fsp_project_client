import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/portfolio_provider.dart';

class RunButton extends StatelessWidget {
  final VoidCallback onResult;

  const RunButton({super.key, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: provider.isLoading
              ? null
              : () async {
                  // 0. 빈 티커 검사
                  if (provider.symbols.any((s) => s.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('빈 티커가 있습니다. 모두 입력하세요.')));
                    return;
                  }

                  // 1. 종료일이 시작일보다 빠른 경우 UI 차단 및 알림
                  if (provider.endDate.isBefore(provider.startDate)) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('날짜 설정 오류'),
                        content: const Text('종료일은 시작일보다 빠를 수 없습니다.\n기간을 다시 설정해주세요.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // 2. 백테스트 실행 및 데이터 존재 여부 검증 (Exception 처리)
                  try {
                    await provider.runBacktest();
                    
                    if (!context.mounted) return;

                    // Provider가 에러를 세팅한 경우
                    if (provider.error != null) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('백테스트 오류'),
                          content: Text(provider.error!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                    } 
                    // 정상적으로 결과가 나온 경우
                    else if (provider.result != null) {
                      onResult();
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('데이터 오류'),
                        content: const Text(
                            '선택한 기간 내에 데이터가 존재하지 않는 종목이 포함되어 있거나,\n데이터를 불러오는 중 문제가 발생했습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: provider.isLoading
                  ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
                  : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            alignment: Alignment.center,
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, color: Colors.white),
                      SizedBox(width: 8),
                      Text('백테스트 실행',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
