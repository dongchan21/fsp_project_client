String formatKoreanAmount(double amount) {
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
String formatKoreanAmountCompact(double amount) {
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
