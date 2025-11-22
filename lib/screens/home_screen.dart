import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_provider.dart';
import 'backtest_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<TextEditingController> _symbolControllers = [];
  final List<TextEditingController> _weightPercentControllers = [];
  final TextEditingController _capitalUnitsController = TextEditingController(); // 만원 단위 입력
  final TextEditingController _dcaUnitsController = TextEditingController(); // DCA 월 적립 만원 단위 입력
  PortfolioProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<PortfolioProvider>();
      _syncControllers();
      _initCapitalUnits();
    });
  }

  void _syncControllers([PortfolioProvider? override]) {
    final p = override ?? _provider ?? (mounted ? context.read<PortfolioProvider>() : null);
    if (p == null) return;
    _symbolControllers.clear();
    _weightPercentControllers.clear();
    for (int i = 0; i < p.symbols.length; i++) {
      _symbolControllers.add(TextEditingController(text: p.symbols[i]));
      _weightPercentControllers.add(TextEditingController(text: (p.weights[i] * 100).toStringAsFixed(0)));
    }
  }

  void _initCapitalUnits() {
    final p = _provider;
    if (p == null) return;
    final units = (p.initialCapital / 10000).round();
    _capitalUnitsController.text = units.toString();
    _capitalUnitsController.addListener(() {
      final v = double.tryParse(_capitalUnitsController.text.trim());
      if (v != null) {
        p.updateInitialCapital(v * 10000);
        setState(() {});
      }
    });
    // DCA 초기화 (만원 단위)
    final dcaUnits = (p.dcaAmount / 10000).round();
    _dcaUnitsController.text = dcaUnits.toString();
    _dcaUnitsController.addListener(() {
      final v = double.tryParse(_dcaUnitsController.text.trim());
      if (v != null) {
        p.updateDcaAmount(v * 10000);
        setState(() {});
      }
    });
  }

  String _formatKoreanAmount(double amount) {
    if (amount <= 0) return '0원';
    final n = amount.round();
    final eok = n ~/ 100000000; // 억
    final man = (n % 100000000) ~/ 10000; // 만원
    String out = '';
    if (eok > 0) out += '${eok}억';
    if (man > 0) {
      if (out.isNotEmpty) out += ' ';
      out += '${man}만원';
    }
    if (out.isEmpty) out = '0원';
    if (out.endsWith('억')) out += '원';
    return out;
  }

  @override
  void dispose() {
    for (final c in _symbolControllers) { c.dispose(); }
    for (final c in _weightPercentControllers) { c.dispose(); }
    _capitalUnitsController.dispose();
    _dcaUnitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI 기반 백테스트 플랫폼',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPortfolioCard(),
            const SizedBox(height: 24),
            _buildDateCard(),
            const SizedBox(height: 24),
            _buildCapitalCard(),
            const SizedBox(height: 32),
            _buildRunButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildPortfolioCard() {
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
                      child: Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('종목 선택', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.symbols.length,
                  itemBuilder: (context, index) => _buildInlineRow(provider, index),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.addStock('', 0.0);
                      _symbolControllers.add(TextEditingController(text: ''));
                      _weightPercentControllers.add(TextEditingController(text: '0'));
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('종목 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 비중', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text(
                          '${(provider.weights.fold(0.0, (s, w) => s + w) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (provider.weights.fold(0.0, (s, w) => s + w) - 1.0).abs() < 0.01 ? Colors.green : Colors.red,
                          ),
                        ),
                        if ((provider.weights.fold(0.0, (s, w) => s + w) - 1.0).abs() < 0.01)
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

  Widget _buildInlineRow(PortfolioProvider provider, int index) {
    // Ensure controllers are in sync with current provider state.
    if (index >= _symbolControllers.length || index >= _weightPercentControllers.length) {
      _syncControllers(provider);
    }
    if (index >= _symbolControllers.length || index >= _weightPercentControllers.length) {
      // Still out of range (provider may have changed asynchronously); render nothing safely.
      return const SizedBox.shrink();
    }
    final symbolCtrl = _symbolControllers[index];
    final weightCtrl = _weightPercentControllers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: symbolCtrl,
              decoration: InputDecoration(
                labelText: '티커',
                border: const OutlineInputBorder(),
                suffixIcon: symbolCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          symbolCtrl.clear();
                          provider.updateStock(index, '', provider.weights[index]);
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (val) => provider.updateStock(index, val.toUpperCase(), provider.weights[index]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(
                labelText: '비중 (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final p = double.tryParse(val);
                if (p != null) {
                  provider.updateStock(index, provider.symbols[index], p / 100.0);
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(width: 8),
            IconButton(
              tooltip: '삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                provider.removeStock(index);
                _syncControllers();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
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
                      child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('백테스트 기간', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateBox(label: '시작일', date: provider.startDate, onChanged: provider.updateStartDate),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDateBox(label: '종료일', date: provider.endDate, onChanged: provider.updateEndDate),
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

  Widget _buildCapitalCard() {
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
                const SizedBox(height: 8),
                Text('총액: ${_formatKoreanAmount(provider.initialCapital)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                _buildDcaSection(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateBox({required String label, required DateTime date, required Function(DateTime) onChanged}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(DateFormat('yyyy년 M월 d일').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDcaSection(PortfolioProvider provider) {
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
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '적립식 금액 (원/월)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: provider.dcaAmount.toStringAsFixed(0)),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) provider.updateDcaAmount(parsed);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildRunButton() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: provider.isLoading
              ? null
              : () async {
                  // 빈 티커 검사
                  if (provider.symbols.any((s) => s.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('빈 티커가 있습니다. 모두 입력하세요.')));
                    return;
                  }
                  await provider.runBacktest();
                  if (!mounted) return;
                  if (provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: ${provider.error}'), backgroundColor: Colors.red));
                  } else if (provider.result != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BacktestResultScreen()));
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: provider.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, color: Colors.white),
                      SizedBox(width: 8),
                      Text('백테스트 실행', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
