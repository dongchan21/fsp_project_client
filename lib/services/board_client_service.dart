import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BoardClientService {
  static final _storage = const FlutterSecureStorage();
  
  static String get _baseUrl => dotenv.env['API_URL']?.replaceAll('/auth', '/board') ?? 'http://localhost:8080/api/board';

  static Future<List<dynamic>> getPosts() async {
    // Ensure trailing slash for the list endpoint
    final url = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts: ${response.statusCode} ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getPost(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load post');
    }
  }

  static Future<void> createPost(String title, String content, Map<String, dynamic> portfolioData) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Not logged in');

    // Ensure trailing slash for the create endpoint
    final url = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
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
}
