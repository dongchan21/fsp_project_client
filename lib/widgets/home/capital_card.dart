import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/portfolio_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/date_utils.dart';

class CapitalCard extends StatefulWidget {
  const CapitalCard({super.key});

  @override
  State<CapitalCard> createState() => _CapitalCardState();
}

class _CapitalCardState extends State<CapitalCard> {
  final TextEditingController _capitalUnitsController = TextEditingController();
  final TextEditingController _dcaAmountController = TextEditingController();
  PortfolioProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<PortfolioProvider>();
      _initControllers();
    });
  }

  @override
  void dispose() {
    _capitalUnitsController.dispose();
    _dcaAmountController.dispose();
    super.dispose();
  }

  void _initControllers() {
    final p = _provider;
    if (p == null) return;
    
    final units = (p.initialCapital / 10000).round();
    _capitalUnitsController.text = units.toString();
    _capitalUnitsController.addListener(() {
      final v = double.tryParse(_capitalUnitsController.text.trim());
      if (v != null) {
        p.updateInitialCapital(v * 10000);
      }
    });

    _dcaAmountController.text = (p.dcaAmount / 10000).toStringAsFixed(0);
    _dcaAmountController.addListener(() {
      final v = double.tryParse(_dcaAmountController.text.trim());
      if (v != null) {
        p.updateDcaAmount(v * 10000);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payments_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('초기 자본', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _capitalUnitsController,
                  decoration: const InputDecoration(
                    labelText: '초기 투자금 (만원 단위)',
                    border: OutlineInputBorder(),
                    hintText: '예: 1 => 1만원, 10000 => 1억원',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('월 적립 투자(DCA)'),
                  value: provider.useDca,
                  onChanged: (val) => provider.toggleUseDca(val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (provider.useDca) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Builder(
                      builder: (_) {
                        // Provider 값이 외부에서 변경되었을 때 컨트롤러 동기화 (선택적)
                        final currentText = _dcaAmountController.text;
                        final targetText = (provider.dcaAmount / 10000).toStringAsFixed(0);
                        if (currentText != targetText && !_dcaAmountController.selection.isValid) {
                           // 입력 중이 아닐 때만 업데이트하거나, 간단히 무시
                           // 여기서는 간단히 놔둠
                        }
                        return TextField(
                          decoration: const InputDecoration(
                            labelText: '적립식 금액 (만원/월)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: _dcaAmountController,
                          // Listener에서 처리하므로 onChanged는 중복일 수 있으나 명시적으로 둠
                          onChanged: (val) {
                            final v = double.tryParse(val.trim());
                            if (v != null) {
                              provider.updateDcaAmount(v * 10000);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text('총액: ${formatKoreanAmount(provider.initialCapital)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (provider.useDca) ...[
                  const SizedBox(height: 4),
                  Text('월 적립금: ${formatKoreanAmount(provider.dcaAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Builder(builder: (_) {
                  final months = diffMonths(provider.startDate, provider.endDate);
                  final totalInvested = provider.initialCapital + (provider.useDca ? provider.dcaAmount * months : 0);
                  final compact = formatKoreanAmountCompact(totalInvested);
                  return Text('총 투자 규모 (기간 반영): $compact', style: const TextStyle(fontWeight: FontWeight.bold));
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
