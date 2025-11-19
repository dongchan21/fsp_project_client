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
  final List<Map<String, dynamic>> history;

  BacktestResult({
    required this.totalReturn,
    required this.annualizedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.history,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    return BacktestResult(
      totalReturn: (json['totalReturn'] as num).toDouble(),
      annualizedReturn: (json['annualizedReturn'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      sharpeRatio: (json['sharpeRatio'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
      history: List<Map<String, dynamic>>.from(json['history'] ?? []),
    );
  }
}
