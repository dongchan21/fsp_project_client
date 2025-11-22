import 'package:flutter/foundation.dart';
import '../models/portfolio.dart';
import 'api_service.dart';

class PortfolioProvider with ChangeNotifier {
  List<String> _symbols = ['AAPL', 'MSFT'];
  List<double> _weights = [0.5, 0.5];
  DateTime _startDate = DateTime(2023, 1, 1);
  DateTime _endDate = DateTime(2024, 12, 31);
  double _initialCapital = 10000;
  double _dcaAmount = 100;
  bool _useDca = false; // 월간 투자 사용 여부

  BacktestResult? _result;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<String> get symbols => _symbols;
  List<double> get weights => _weights;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  double get initialCapital => _initialCapital;
  double get dcaAmount => _dcaAmount;
  bool get useDca => _useDca;
  BacktestResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  void updateSymbols(List<String> symbols) {
    _symbols = symbols;
    notifyListeners();
  }

  void updateWeights(List<double> weights) {
    _weights = weights;
    notifyListeners();
  }

  void updateStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void updateEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void updateInitialCapital(double capital) {
    _initialCapital = capital;
    notifyListeners();
  }

  void updateDcaAmount(double amount) {
    _dcaAmount = amount;
    notifyListeners();
  }

  void toggleUseDca(bool value) {
    _useDca = value;
    if (!_useDca) {
      // 사용 안 할 때 금액 초기화 (선택사항) 유지하고 싶으면 제거
      _dcaAmount = 0;
    }
    notifyListeners();
  }

  void addStock(String symbol, double weight) {
    _symbols.add(symbol);
    _weights.add(weight);
    notifyListeners();
  }

  // 여러 종목을 동일 비중으로 추가 (totalWeight는 전체에서 차지할 비중 0~1)
  bool addMultipleEqual(List<String> symbols, double totalWeight) {
    final currentSum = _weights.fold(0.0, (s, w) => s + w);
    if (totalWeight <= 0 || symbols.isEmpty) return false;
    if (currentSum + totalWeight > 1.0001) {
      return false; // 추가 불가 (총 비중 초과)
    }
    final each = totalWeight / symbols.length;
    for (final s in symbols) {
      _symbols.add(s.toUpperCase());
      _weights.add(each);
    }
    notifyListeners();
    return true;
  }

  void removeStock(int index) {
    if (index >= 0 && index < _symbols.length) {
      _symbols.removeAt(index);
      _weights.removeAt(index);
      notifyListeners();
    }
  }

  void updateStock(int index, String symbol, double weight) {
    if (index >= 0 && index < _symbols.length) {
      _symbols[index] = symbol;
      _weights[index] = weight;
      notifyListeners();
    }
  }

  // Run backtest
  Future<void> runBacktest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.runBacktest(
        symbols: _symbols,
        weights: _weights,
        startDate: _startDate,
        endDate: _endDate,
        initialCapital: _initialCapital,
        dcaAmount: _useDca ? _dcaAmount : 0,
      );

      _result = BacktestResult.fromJson(response);
      // 수신 응답 로깅 (요약)
      try {
        final histLen = _result?.history.length ?? 0;
        final first = histLen > 0 ? _result!.history.first['date'] : null;
        final last = histLen > 0 ? _result!.history.last['date'] : null;
        debugPrint('✅ Parsed Backtest: len=$histLen, first=$first, last=$last, totalReturn=${_result?.totalReturn}, annualized=${_result?.annualizedReturn}');
      } catch (_) {}
      // 응답 히스토리의 첫 날짜를 실제 시작일로 반영
      try {
        if (_result != null && _result!.history.isNotEmpty) {
          final firstDate = _result!.history.first['date'];
          if (firstDate is String && firstDate.isNotEmpty) {
            final parsed = DateTime.parse(firstDate);
            _startDate = parsed;
            debugPrint('📅 Effective startDate set from response: $_startDate');
          }
        }
      } catch (_) {
        // 파싱 실패 시 조용히 무시 (UI는 기존 값 유지)
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _result = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
