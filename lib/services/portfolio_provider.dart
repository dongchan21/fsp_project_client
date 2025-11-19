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

  void addStock(String symbol, double weight) {
    _symbols.add(symbol);
    _weights.add(weight);
    notifyListeners();
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
        dcaAmount: _dcaAmount,
      );

      _result = BacktestResult.fromJson(response);
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
