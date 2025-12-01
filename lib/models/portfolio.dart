class Portfolio {
  final List<String> symbols;
  final List<double> weights;
  final DateTime startDate;
  final DateTime endDate;
  final double initialCapital;
  final double dcaAmount;

  Portfolio({
    required this.symbols,
    required this.weights,
    required this.startDate,
    required this.endDate,
    required this.initialCapital,
    required this.dcaAmount,
  });

  // Validate that weights sum to 1.0
  bool isValid() {
    if (symbols.isEmpty || symbols.length != weights.length) {
      return false;
    }
    final sum = weights.reduce((a, b) => a + b);
    return (sum - 1.0).abs() < 0.01; // Allow small floating point errors
  }

  Map<String, dynamic> toJson() {
    return {
      'symbols': symbols,
      'weights': weights,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'initialCapital': initialCapital,
      'dcaAmount': dcaAmount,
    };
  }
}

class BacktestResult {
  final double totalReturn;
  final double annualizedReturn;
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;
  
  // [수정됨] 차트 그릴 때 원금 계산을 위해 필요한 필드 추가
  final double initialCapital;
  final double dcaAmount;
  
  final List<Map<String, dynamic>> history;
  final List<dynamic> annualReturns; // 추가
  final Map<String, dynamic>? benchmark;

  BacktestResult({
    required this.totalReturn,
    required this.annualizedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.initialCapital, // 생성자 추가
    required this.dcaAmount,      // 생성자 추가
    required this.history,
    required this.annualReturns, // 추가
    this.benchmark,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    return BacktestResult(
      totalReturn: (json['totalReturn'] as num).toDouble(),
      annualizedReturn: (json['annualizedReturn'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      sharpeRatio: (json['sharpeRatio'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
      
      // [수정됨] JSON에서 값 꺼내오기 (혹시 null이면 0.0 처리)
      initialCapital: (json['initialCapital'] as num?)?.toDouble() ?? 0.0,
      dcaAmount: (json['dcaAmount'] as num?)?.toDouble() ?? 0.0,
      
      history: List<Map<String, dynamic>>.from(json['history'] ?? []),
      annualReturns: List<dynamic>.from(json['annualReturns'] ?? []), // 추가
      benchmark: json['benchmark'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReturn': totalReturn,
      'annualizedReturn': annualizedReturn,
      'volatility': volatility,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
      'initialCapital': initialCapital,
      'dcaAmount': dcaAmount,
      'history': history,
      'annualReturns': annualReturns,
      'benchmark': benchmark,
    };
  }
}