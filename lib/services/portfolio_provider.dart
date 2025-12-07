import 'package:flutter/foundation.dart';
import '../models/portfolio.dart';
import 'api_service.dart';

// [Helper] compute용 모델 파싱 함수 (Top-level)
BacktestResult _parseBacktestResult(Map<String, dynamic> json) {
  return BacktestResult.fromJson(json);
}

class PortfolioProvider with ChangeNotifier {
  // 기본값: AAPL 100%
  List<String> _symbols = ['AAPL'];
  List<double> _weights = [1.0];
  DateTime _startDate = DateTime(2023, 1, 1);
  DateTime _endDate = DateTime.now();
  double _initialCapital = 10000;
  double _dcaAmount = 100;
  bool _useDca = false; // 월간 투자 사용 여부

  BacktestResult? _result;
  bool _isLoading = false;
  String? _error;
  
  // AI 분석 프리페치용 Future
  Future<Map<String, dynamic>>? _aiAnalysisFuture;

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
  Future<Map<String, dynamic>>? get aiAnalysisFuture => _aiAnalysisFuture;

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
    // 추가 후 모든 비중을 합이 약 1.0이 되도록 균등화
    _symbols.add(symbol);
    _weights.add(weight);
    if (_symbols.isNotEmpty) {
      final equal = 1.0 / _symbols.length;
      for (int i = 0; i < _weights.length; i++) {
        _weights[i] = equal;
      }
    }
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

  // 백테스트 실행
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

      // [최적화] 모델 파싱도 별도 스레드(Isolate)에서 수행
      _result = await compute(_parseBacktestResult, response);
      
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

      // [AI 분석 프리페치 시작]
      // 백테스트 결과가 나왔으므로, 사용자가 요청하기 전에 미리 AI 분석을 시작합니다.
      _startAiAnalysisPrefetch();

    } catch (e) {
      _error = e.toString();
      _result = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startAiAnalysisPrefetch() {
    if (_result == null) return;

    _aiAnalysisFuture = Future(() async {
      debugPrint('🚀 AI Analysis Prefetch Started...');
      
      // 1. 성과 지표 요약 데이터 준비
      final summary = {
        'totalReturn': _result!.totalReturn,
        'annualizedReturn': _result!.annualizedReturn,
        'volatility': _result!.volatility,
        'sharpeRatio': _result!.sharpeRatio,
        'maxDrawdown': _result!.maxDrawdown,
        'annualReturn': _result!.annualizedReturn,
        'mdd': _result!.maxDrawdown,
        'sharpe': _result!.sharpeRatio,
      };

      // 2. 서버에 분석 요청 (점수 및 텍스트 생성)
      final analysisResult = await ApiService.analyzeInsight(summary: summary);
      
      if (analysisResult.containsKey('error')) {
        throw Exception(analysisResult['error']);
      }

      final score = analysisResult['score'];
      final analysis = analysisResult['analysis'];

      // 3. AI 인사이트 생성 요청
      final portfolio = {
        'symbols': _symbols,
        'weights': _weights,
      };

      final response = await ApiService.generateAiInsight(
        score: score,
        analysis: analysis,
        portfolio: portfolio,
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      debugPrint('✅ AI Analysis Prefetch Completed!');
      return {
        'score': score,
        'aiInsight': response['aiInsight'],
      };
    });
  }
}
