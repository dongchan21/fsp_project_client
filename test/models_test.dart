import 'package:flutter_test/flutter_test.dart';
import 'package:fsp_client/models/portfolio.dart';

void main() {
  group('Portfolio Model Tests', () {
    test('isValid should return true for valid weights', () {
      final portfolio = Portfolio(
        symbols: ['AAPL', 'GOOG'],
        weights: [0.5, 0.5],
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 12, 31),
        initialCapital: 10000,
        dcaAmount: 100,
      );
      expect(portfolio.isValid(), true);
    });

    test('isValid should return false for invalid weights sum', () {
      final portfolio = Portfolio(
        symbols: ['AAPL', 'GOOG'],
        weights: [0.5, 0.4], // Sum 0.9
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 12, 31),
        initialCapital: 10000,
        dcaAmount: 100,
      );
      expect(portfolio.isValid(), false);
    });

    test('isValid should return false for mismatched length', () {
      final portfolio = Portfolio(
        symbols: ['AAPL'],
        weights: [0.5, 0.5],
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 12, 31),
        initialCapital: 10000,
        dcaAmount: 100,
      );
      expect(portfolio.isValid(), false);
    });

    test('toJson should serialize correctly', () {
      final date = DateTime(2023, 1, 1);
      final portfolio = Portfolio(
        symbols: ['AAPL'],
        weights: [1.0],
        startDate: date,
        endDate: date,
        initialCapital: 10000,
        dcaAmount: 100,
      );
      
      final json = portfolio.toJson();
      expect(json['symbols'], ['AAPL']);
      expect(json['weights'], [1.0]);
      expect(json['startDate'], '2023-01-01');
      expect(json['initialCapital'], 10000);
    });
  });
}
