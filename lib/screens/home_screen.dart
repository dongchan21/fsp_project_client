import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import 'backtest_result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Backtest'),
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
                  'Portfolio Composition',
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
                  label: const Text('Add Stock'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Weight: ${provider.weights.fold(0.0, (sum, w) => sum + w).toStringAsFixed(2)}',
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
        subtitle: Text('Weight: ${(provider.weights[index] * 100).toStringAsFixed(1)}%'),
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
                  'Backtest Parameters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(
                  context,
                  'Start Date',
                  provider.startDate,
                  (date) => provider.updateStartDate(date),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  context,
                  'End Date',
                  provider.endDate,
                  (date) => provider.updateEndDate(date),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  'Initial Capital (\$)',
                  provider.initialCapital,
                  (value) => provider.updateInitialCapital(value),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  'DCA Amount (\$/month)',
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
          firstDate: DateTime(2020),
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
            Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
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
                  'Run Backtest',
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
        title: const Text('Add Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: 'Symbol'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (0-1)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
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
        title: const Text('Edit Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: 'Symbol'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (0-1)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
