import 'package:flutter_test/flutter_test.dart';
import 'package:fsp_client/utils/date_utils.dart';
import 'package:fsp_client/utils/format_utils.dart';

void main() {
  group('DateUtils Tests', () {
    test('diffMonths should return inclusive month count', () {
      final start = DateTime(2023, 1, 15);
      final end = DateTime(2023, 1, 20);
      expect(diffMonths(start, end), 1);

      final end2 = DateTime(2023, 2, 1);
      expect(diffMonths(start, end2), 2);

      final end3 = DateTime(2024, 1, 15);
      expect(diffMonths(start, end3), 13);
    });
  });

  group('FormatUtils Tests', () {
    test('formatKoreanAmount should format correctly', () {
      expect(formatKoreanAmount(0), '0원');
      expect(formatKoreanAmount(10000), '1만원');
      expect(formatKoreanAmount(25000), '2만원'); // Integer division in code: 25000 ~/ 10000 = 2
      expect(formatKoreanAmount(100000000), '1억원');
      expect(formatKoreanAmount(150000000), '1억 5000만원');
      expect(formatKoreanAmount(100050000), '1억 5만원');
    });

    test('formatKoreanAmountCompact should format correctly', () {
      expect(formatKoreanAmountCompact(0), '0원');
      expect(formatKoreanAmountCompact(150000000), '1.5억');
      expect(formatKoreanAmountCompact(1234000000), '12.34억');
      expect(formatKoreanAmountCompact(12000000), '1200만원');
    });
  });
}
