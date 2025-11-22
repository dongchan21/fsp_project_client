import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import 'backtest_result_screen.dart';
import 'package:dotted_border/dotted_border.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _multiSymbolController = TextEditingController();
  final TextEditingController _multiPercentController = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백테스트 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(context),
            const SizedBox(height: 16),
            _buildPortfolioSection(context),
            const SizedBox(height: 24),
            _buildParametersSection(context),
            const SizedBox(height: 32),
            _buildRunButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('백테스트 설정', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('종목과 투자 조건을 설정하세요', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '종목 선택',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.symbols.length,
                  itemBuilder: (context, index) {
                    return _buildStockItem(context, provider, index);
                  },
                ),
                const SizedBox(height: 12),
                _buildMultiAddArea(provider),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showAddStockDialog(context, provider),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('단일 종목 추가'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 비중',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          '${(provider.weights.fold(0.0, (sum, w) => sum + w) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (provider.weights.fold(0.0, (sum, w) => sum + w) - 1.0).abs() < 0.01
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        if ((provider.weights.fold(0.0, (sum, w) => sum + w) - 1.0).abs() < 0.01)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check, size: 16, color: Colors.green),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildMultiAddArea(PortfolioProvider provider) {
    final remaining = (1.0 - provider.weights.fold(0.0, (s, w) => s + w)).clamp(0, 1);
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      dashPattern: const [6, 4],
      color: Colors.grey.shade400,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _multiSymbolController,
                    decoration: const InputDecoration(
                      hintText: '예: AAPL, TSLA, MSFT',
                      border: OutlineInputBorder(),
                      labelText: '종목 목록',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _multiPercentController,
                    decoration: const InputDecoration(
                      labelText: '비중 %',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('남은 비중: ${(remaining * 100).toStringAsFixed(0)}%'),
                ElevatedButton.icon(
                  onPressed: () {
                    final raw = _multiSymbolController.text.trim();
                    if (raw.isEmpty) return;
                    final symbols = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final percent = double.tryParse(_multiPercentController.text.trim());
                    if (percent == null) {
                      _showSnack('비중 숫자를 확인하세요');
                      return;
                    }
                    final decimal = percent / 100.0;
                    if (decimal <= 0) {
                      _showSnack('비중은 0보다 커야 합니다');
                      return;
                    }
                    if (decimal - remaining > 0.0001) {
                      _showSnack('남은 비중을 초과했습니다');
                      return;
                    }
                    final ok = provider.addMultipleEqual(symbols, decimal);
                    if (!ok) {
                      _showSnack('추가 실패: 총 비중 초과');
                    } else {
                      _multiSymbolController.clear();
                      // 자동으로 남은 비중 100으로 표시 조정
                      _multiPercentController.text = ( (1.0 - provider.weights.fold(0.0, (s, w) => s + w)) * 100 ).toStringAsFixed(0);
                      _showSnack('종목 ${symbols.length}개 추가됨');
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('종목 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }


  Widget _buildStockItem(BuildContext context, PortfolioProvider provider, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(provider.symbols[index]),
        subtitle: Text('비중: ${(provider.weights[index] * 100).toStringAsFixed(1)}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditStockDialog(context, provider, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => provider.removeStock(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersSection(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '백테스트 기간',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker(
                  context,
                  '시작일',
                  provider.startDate,
                  (date) => provider.updateStartDate(date),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  context,
                  '종료일',
                  provider.endDate,
                  (date) => provider.updateEndDate(date),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  '초기 투자금 (원)',
                  provider.initialCapital,
                  (value) => provider.updateInitialCapital(value),
                ),
                const SizedBox(height: 12),
                _buildDcaSection(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          // 최소 선택 가능 날짜 확장 (백테스트 데이터 커버 범위에 맞게 조정)
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('yyyy-MM-dd', 'ko_KR').format(date)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: value.toString()),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }

  Widget _buildRunButton(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: provider.isLoading
              ? null
              : () async {
                  await provider.runBacktest();
                  if (context.mounted) {
                    if (provider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('오류: ${provider.error}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (provider.result != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BacktestResultScreen(),
                        ),
                      );
                    }
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '백테스트 실행',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showAddStockDialog(BuildContext context, PortfolioProvider provider) {
    final symbolController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('종목 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: '종목'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: '비중 (0-1)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final symbol = symbolController.text.toUpperCase();
              final weight = double.tryParse(weightController.text);
              if (symbol.isNotEmpty && weight != null) {
                provider.addStock(symbol, weight);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditStockDialog(
    BuildContext context,
    PortfolioProvider provider,
    int index,
  ) {
    final symbolController = TextEditingController(text: provider.symbols[index]);
    final weightController = TextEditingController(text: provider.weights[index].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('종목 편집'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: '종목'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: '비중 (0-1)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final symbol = symbolController.text.toUpperCase();
              final weight = double.tryParse(weightController.text);
              if (symbol.isNotEmpty && weight != null) {
                provider.updateStock(index, symbol, weight);
                Navigator.pop(context);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Widget _buildDcaSection(BuildContext context, PortfolioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('월간 투자 (DCA)', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('월 적립 투자 사용'),
          value: provider.useDca,
          onChanged: (val) => provider.toggleUseDca(val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: provider.useDca
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildNumberField(
                    '적립식 금액 (원/월)',
                    provider.dcaAmount,
                    (value) => provider.updateDcaAmount(value),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
