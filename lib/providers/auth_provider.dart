import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_client_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  // 앱 시작 시 토큰 확인
  Future<void> checkLoginStatus() async {
    final token = await AuthClientService.getToken();
    if (token != null) {
      _isLoggedIn = true;
      try {
        final payload = _decodeJwtPayload(token);
        _user = {
          'id': payload['id'],
          'email': payload['email'],
          'nickname': payload['nickname'],
        };
      } catch (e) {
        debugPrint('Token decode error: $e');
      }
      notifyListeners();
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }
    return payloadMap;
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await AuthClientService.login(email, password);
      _isLoggedIn = true;
      _user = data['user'];
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String nickname) async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthClientService.signup(email, password, nickname);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthClientService.logout();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}
