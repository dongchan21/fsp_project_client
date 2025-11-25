import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StockSearchService {
  // Yahoo Finance Autocomplete API
  static const String _baseUrl = "https://query2.finance.yahoo.com/v1/finance/search";

  Future<List<Map<String, String>>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];

    // quotesCount: 가져올 결과 개수
    // newsCount: 뉴스 데이터는 필요 없으므로 0
    String requestUrl = '$_baseUrl?q=$query&quotesCount=20&newsCount=0';

    // Flutter Web 환경에서는 CORS 정책으로 인해 직접 호출이 차단될 수 있습니다.
    // 이를 우회하기 위해 개발용 CORS 프록시를 사용합니다.
    if (kIsWeb) {
      requestUrl = 'https://corsproxy.io/?' + Uri.encodeComponent(requestUrl);
    }

    final url = Uri.parse(requestUrl);
    
    try {
      final response = await http.get(url, headers: {
        // 봇 차단을 방지하기 위한 User-Agent 설정
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['quotes'] == null) return [];

        final quotes = data['quotes'] as List<dynamic>;

        return quotes.map<Map<String, String>>((item) {
          return {
            'symbol': item['symbol']?.toString() ?? '',
            'name': item['shortname']?.toString() ?? item['longname']?.toString() ?? 'Unknown',
            'exchange': item['exchange']?.toString() ?? '',
            'type': item['quoteType']?.toString() ?? '',
          };
        }).where((item) => item['symbol']!.isNotEmpty).toList();
      } else {
        print('API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }
}
