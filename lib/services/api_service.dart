import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  // 백테스트 실행
  static Future<Map<String, dynamic>> runBacktest({
    required List<String> symbols,
    required List<double> weights,
    required DateTime startDate,
    required DateTime endDate,
    required double initialCapital,
    required double dcaAmount,
  }) async {
    final url = Uri.parse('$baseUrl/backtest/run');
    
    final body = jsonEncode({
      'symbols': symbols,
      'weights': weights,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'initialCapital': initialCapital,
      'dcaAmount': dcaAmount,
    });

    print('📤 Sending backtest request to: $url');
    print('Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to run backtest: ${response.body}');
    }
  }

  // 인사이트 분석
  static Future<Map<String, dynamic>> analyzeInsight({
    required Map<String, dynamic> summary,
  }) async {
    final url = Uri.parse('$baseUrl/insight/analyze');
    
    final body = jsonEncode({'summary': summary});

    print('📤 Sending insight analysis request to: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze insight: ${response.body}');
    }
  }

  // AI 인사이트 생성
  static Future<Map<String, dynamic>> generateAiInsight({
    required int score,
    required Map<String, dynamic> analysis,
    required Map<String, dynamic> portfolio,
  }) async {
    final url = Uri.parse('$baseUrl/insight/ai');
    
    final body = jsonEncode({
      'score': score,
      'analysis': analysis,
      'portfolio': portfolio,
    });

    print('📤 Sending AI insight request to: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate AI insight: ${response.body}');
    }
  }
}
