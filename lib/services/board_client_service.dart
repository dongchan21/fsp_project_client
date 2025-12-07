import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BoardClientService {
  static final _storage = const FlutterSecureStorage();
  
  static String get _baseUrl => 'https://labourless-molly-jack.ngrok-free.dev/api/board';

  static Future<List<dynamic>> getPosts() async {
    // 목록 엔드포인트에 후행 슬래시 보장
    final url = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts: ${response.statusCode} ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getPost(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load post');
    }
  }

  static Future<void> createPost(String title, String content, Map<String, dynamic> portfolioData) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Not logged in');

    // 생성 엔드포인트에 후행 슬래시 보장
    final url = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'portfolioData': portfolioData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create post');
    }
  }

  static Future<void> deletePost(int id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Not logged in');

    final url = _baseUrl.endsWith('/') ? '$_baseUrl$id' : '$_baseUrl/$id';

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to delete post');
    }
  }
}
