import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/portfolio_provider.dart';
import '../services/stock_search_service.dart';
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
  final TextEditingController _dcaAmountController = TextEditingController(); // 월 적립식 금액 (원/월) 입력
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
    }
  });
  // 월 적립식 금액 초기화 (만원 단위)
  _dcaAmountController.text = (p.dcaAmount / 10000).toStringAsFixed(0);
  _dcaAmountController.addListener(() {
    final v = double.tryParse(_dcaAmountController.text.trim());
    if (v != null) {
      p.updateDcaAmount(v * 10000);
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

  // Compact: 150,000,000 => 1.5억, 12,000,000 => 1200만원, 1,234,000,000 => 12.34억
  String _formatKoreanAmountCompact(double amount) {
    if (amount <= 0) return '0원';
    final n = amount.round();
    final eok = n / 100000000.0; // 억 단위 실수
    if (eok >= 1) {
      // Show up to 2 decimals but trim trailing zeros
      String s = eok.toStringAsFixed(eok >= 10 ? 2 : 2); // uniform 2 decimals
      s = s.replaceAll(RegExp(r'\.0+'), '');
      // Manual trim of trailing zeros and dot
      while (s.contains('.') && (s.endsWith('0'))) {
        s = s.substring(0, s.length - 1);
      }
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
      return s + '억';
    } else {
      final man = n / 10000.0; // 만원 단위
      String s = man.toStringAsFixed(man >= 100 ? 0 : (man >= 10 ? 1 : 2));
      return s + '만원';
    }
  }

  int _diffMonths(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month) + 1; // inclusive month count
  }

  @override
  void dispose() {
    for (final c in _symbolControllers) { c.dispose(); }
    for (final c in _weightPercentControllers) { c.dispose(); }
    _capitalUnitsController.dispose();
    _dcaAmountController.dispose();
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
                      provider.addStock('', 0.0); // triggers equalization
                      _syncControllers(provider); // refresh controllers to equal weights
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '티커 입력 가이드',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '백테스트를 수행하려면 Yahoo Finance에 등록된 정확한 티커를 입력해야 합니다. (예: 삼성전자 → 005930.KS)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse('https://finance.yahoo.com/');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: const Text(
                          'Yahoo Finance에서 티커 검색하기 >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.blueGrey),
                      tooltip: '종목 검색',
                      onPressed: () => _showStockSearchPopup(context, index, provider),
                    ),
                    if (symbolCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          symbolCtrl.clear();
                          provider.updateStock(index, '', provider.weights[index]);
                        },
                      ),
                  ],
                ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      '정확한 분석 결과를 위해 1년 이상의 기간 설정을 권장합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
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
                      final currentText = _dcaAmountController.text;
                      final targetText = (provider.dcaAmount / 10000).toStringAsFixed(0);
                      if (currentText != targetText) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _dcaAmountController.text = targetText;
                        });
                      }
                      return TextField(
                        decoration: const InputDecoration(
                          labelText: '적립식 금액 (만원/월)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _dcaAmountController,
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
              Text('총액: ${_formatKoreanAmount(provider.initialCapital)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (provider.useDca) ...[
                const SizedBox(height: 4),
                Text('월 적립금: ${_formatKoreanAmount(provider.dcaAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 4),
              Builder(builder: (_) {
                final months = _diffMonths(provider.startDate, provider.endDate);
                final totalInvested = provider.initialCapital + (provider.useDca ? provider.dcaAmount * months : 0);
                final compact = _formatKoreanAmountCompact(totalInvested);
                return Text('총 투자 규모 (기간 반영): $compact', style: const TextStyle(fontWeight: FontWeight.bold));
              }),
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
  // 더 이상 사용하지 않음. (DCA UI는 _buildCapitalCard에 직접 구현)
  return const SizedBox.shrink();
}

  Widget _buildRunButton() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: provider.isLoading
              ? null
              : () async {
                  // [기존] 0. 빈 티커 검사
                  if (provider.symbols.any((s) => s.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('빈 티커가 있습니다. 모두 입력하세요.')));
                    return;
                  }

                  // [추가 1] 종료일이 시작일보다 빠른 경우 UI 차단 및 알림
                  // 날짜의 시/분/초 차이로 인한 오류를 막기 위해 날짜 부분만 비교하거나 compareTo 사용
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

                  // [추가 2] 백테스트 실행 및 데이터 존재 여부 검증 (Exception 처리)
                  try {
                    await provider.runBacktest();
                    
                    if (!mounted) return;

                    // Provider가 에러를 세팅한 경우 (예: "OOO 종목의 데이터가 해당 기간에 없습니다")
                    if (provider.error != null) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('백테스트 오류'),
                          content: Text(provider.error!), // Provider에서 설정한 구체적인 에러 메시지 출력
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BacktestResultScreen()));
                    }
                  } catch (e) {
                    // Provider 내부에서 unhandled exception이 발생했을 경우 대비
                    if (!mounted) return;
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

  void _showStockSearchPopup(BuildContext context, int index, PortfolioProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return _StockSearchDialog(
          onSelected: (symbol) {
            provider.updateStock(index, symbol, provider.weights[index]);
            _syncControllers(provider);
            setState(() {});
          },
        );
      },
    );
  }
}

class _StockSearchDialog extends StatefulWidget {
  final Function(String) onSelected;

  const _StockSearchDialog({required this.onSelected});

  @override
  State<_StockSearchDialog> createState() => _StockSearchDialogState();
}

class _StockSearchDialogState extends State<_StockSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final StockSearchService _searchService = StockSearchService();
  List<Map<String, String>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _searchService.searchStocks(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600), // 너비 확대
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '종목 검색',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '종목명(영문) 또는 티커 검색 (예: Samsung, AAPL)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* Yahoo Finance 기반이므로 한국어 대신 영문 종목명이나 티커로 검색해주세요.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),

            // List Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.manage_search,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? '검색어를 입력하세요'
                                    : '검색 결과가 없습니다',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              title: Text(
                                item['symbol']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                '${item['name']} • ${item['exchange']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                              onTap: () {
                                widget.onSelected(item['symbol']!);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
