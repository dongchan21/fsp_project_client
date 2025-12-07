import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/portfolio_provider.dart';
import 'stock_search_dialog.dart';

class PortfolioCard extends StatefulWidget {
  const PortfolioCard({super.key});

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  final List<TextEditingController> _symbolControllers = [];
  final List<TextEditingController> _weightPercentControllers = [];
  PortfolioProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<PortfolioProvider>();
      _syncControllers();
    });
  }

  @override
  void dispose() {
    for (final c in _symbolControllers) { c.dispose(); }
    for (final c in _weightPercentControllers) { c.dispose(); }
    super.dispose();
  }

  void _syncControllers([PortfolioProvider? override]) {
    final p = override ?? _provider ?? (mounted ? context.read<PortfolioProvider>() : null);
    if (p == null) return;
    
    // 기존 컨트롤러 개수와 데이터 개수가 다르면 재생성
    if (_symbolControllers.length != p.symbols.length) {
      // 기존 것 정리
      for (final c in _symbolControllers) { c.dispose(); }
      for (final c in _weightPercentControllers) { c.dispose(); }
      _symbolControllers.clear();
      _weightPercentControllers.clear();

      for (int i = 0; i < p.symbols.length; i++) {
        _symbolControllers.add(TextEditingController(text: p.symbols[i]));
        _weightPercentControllers.add(TextEditingController(text: (p.weights[i] * 100).toStringAsFixed(0)));
      }
    } else {
      // 개수가 같으면 값만 업데이트 (사용자가 입력 중이 아닐 때만 하는 게 좋지만, 여기선 단순화)
      for (int i = 0; i < p.symbols.length; i++) {
        if (_symbolControllers[i].text != p.symbols[i]) {
          _symbolControllers[i].text = p.symbols[i];
        }
        final wText = (p.weights[i] * 100).toStringAsFixed(0);
        if (_weightPercentControllers[i].text != wText) {
          _weightPercentControllers[i].text = wText;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        // Provider 상태가 변경되었을 때 컨트롤러 동기화 확인
        if (_symbolControllers.length != provider.symbols.length) {
           _syncControllers(provider);
        }

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
                      provider.addStock('', 0.0); // 균등화 트리거
                      _syncControllers(provider); // 컨트롤러를 균등 비중으로 새로고침
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
      // This might happen during rebuilds if sync hasn't happened yet
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
                  // setState(() {}); // Provider notifies listeners, which rebuilds Consumer
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
                _syncControllers(provider);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  void _showStockSearchPopup(BuildContext context, int index, PortfolioProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return StockSearchDialog(
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
