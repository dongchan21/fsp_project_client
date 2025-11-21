import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import 'backtest_result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포트폴리오 백테스트'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPortfolioSection(context),
            const SizedBox(height: 24),
            _buildParametersSection(context),
            const SizedBox(height: 24),
            _buildRunButton(context),
          ],
        ),
      ),
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
                Text(
                  '포트폴리오 구성',
                  style: Theme.of(context).textTheme.titleLarge,
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
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddStockDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('종목 추가'),
                ),
                const SizedBox(height: 8),
                Text(
                  '총 비중: ${provider.weights.fold(0.0, (sum, w) => sum + w).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (provider.weights.fold(0.0, (sum, w) => sum + w) - 1.0).abs() < 0.01
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                Text(
                  '백테스트 설정',
                  style: Theme.of(context).textTheme.titleLarge,
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
                  '초기 자본 (원)',
                  provider.initialCapital,
                  (value) => provider.updateInitialCapital(value),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  '적립식 금액 (원/월)',
                  provider.dcaAmount,
                  (value) => provider.updateDcaAmount(value),
                ),
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
        return ElevatedButton(
          onPressed: provider.isLoading
              ? null
              : () async {
                  await provider.runBacktest();
                  if (context.mounted) {
                    if (provider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${provider.error}'),
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
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
          child: provider.isLoading
              ? const CircularProgressIndicator()
              : const Text(
                  '백테스트 실행',
                  style: TextStyle(fontSize: 18),
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
}
