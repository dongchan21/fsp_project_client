import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://labourless-molly-jack.ngrok-free.dev/api';
  static const _storage = FlutterSecureStorage();

  // [Helper] compute용 JSON 파싱 함수 (Top-level 혹은 static이어야 함)
  static Map<String, dynamic> _parseJson(String source) {
    return jsonDecode(source) as Map<String, dynamic>;
  }

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

    debugPrint('📤 Sending backtest request to: $url');
    debugPrint('Body: $body');

    // 토큰이 있으면 헤더에 추가
    final token = await _storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    debugPrint('📥 Response status: ${response.statusCode}');
    final preview = response.body.length > 200
      ? response.body.substring(0, 200) + '...'
      : response.body;
    debugPrint('📥 Response body (preview): $preview');

    if (response.statusCode == 200) {
      // [최적화] 대용량 JSON 파싱을 별도 Isolate(스레드)에서 수행하여 UI 버벅임 방지
      return await compute(_parseJson, response.body);
    } else {
      debugPrint('❌ Backtest failed. Body: ${response.body}');
      throw Exception('Failed to run backtest: ${response.body}');
    }
  }

  // 백테스트 히스토리 조회
  static Future<List<dynamic>> getBacktestHistory() async {
    final url = Uri.parse('$baseUrl/backtest/history');
    final token = await _storage.read(key: 'jwt_token');
    
    if (token == null) throw Exception('Not logged in');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  // 인사이트 분석
  static Future<Map<String, dynamic>> analyzeInsight({
    required Map<String, dynamic> summary,
  }) async {
    final url = Uri.parse('$baseUrl/insight/analyze');
    
    final body = jsonEncode({'summary': summary});

    debugPrint('📤 Sending insight analysis request to: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: body,
    );

    debugPrint('📥 Response status: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return await compute(_parseJson, response.body);
    } else {
      debugPrint('❌ Insight analyze failed. Body: ${response.body}');
      throw Exception('Failed to analyze insight: ${response.body}');
    }
  }

  // AI 인사이트 생성
  static Future<Map<String, dynamic>> generateAiInsight({
    required Map<String, dynamic> score,
    required Map<String, dynamic> analysis,
    required Map<String, dynamic> portfolio,
  }) async {
    final url = Uri.parse('$baseUrl/insight/ai');
    
    final body = jsonEncode({
      'score': score,
      'analysis': analysis,
      'portfolio': portfolio,
    });

    debugPrint('📤 Sending AI insight request to: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: body,
    );

    debugPrint('📥 Response status: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return await compute(_parseJson, response.body);
    } else {
      debugPrint('❌ AI insight failed. Body: ${response.body}');
      throw Exception('Failed to generate AI insight: ${response.body}');
    }
  }
}
