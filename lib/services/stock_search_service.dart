import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StockSearchService {
  // 내 서버의 검색 API 주소
  static const String _baseUrl = "http://localhost:8080/api/stocks/search";

  Future<List<Map<String, String>>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('$_baseUrl?query=$query');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['results'] == null) return [];

        final results = data['results'] as List<dynamic>;

        return results.map<Map<String, String>>((item) {
          return {
            'symbol': item['symbol']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown',
            'exchange': item['exchange']?.toString() ?? '',
            'type': item['type']?.toString() ?? '',
          };
        }).toList();
      } else {
        if (kDebugMode) {
          print('API Error: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching stocks: $e');
      }
      return [];
    }
  }
}
