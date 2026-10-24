import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const baseUrl = 'https://hotel-booking-backend-fz9h.onrender.com';
  static const _tokenKey = 'hotel_booking_jwt';
  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<String?> get token => _storage.read(key: _tokenKey);
  Future<void> saveToken(String value) =>
      _storage.write(key: _tokenKey, value: value);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<dynamic> get(String path,
          {Map<String, String>? query, bool auth = false}) =>
      _send('GET', path, query: query, auth: auth);
  Future<dynamic> post(String path,
          {Map<String, dynamic>? body, bool auth = false}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path,
          {Map<String, dynamic>? body, bool auth = false}) =>
      _send('PUT', path, body: body, auth: auth);
  Future<dynamic> patch(String path,
          {Map<String, dynamic>? body, bool auth = false}) =>
      _send('PATCH', path, body: body, auth: auth);
  Future<dynamic> delete(String path, {bool auth = false}) =>
      _send('DELETE', path, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final value = await token;
      if (value == null || value.trim().isEmpty) {
        throw const ApiException(
          401,
          'Phiên đăng nhập không còn hiệu lực. Vui lòng đăng nhập lại.',
        );
      }
      headers['Authorization'] = 'Bearer ${value.trim()}';
    }
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      // Render may need several seconds to wake from an idle state. Keep one
      // request only (registration is a mutation) but allow the server time
      // to return its actual validation/conflict response.
      final response = await _client.send(request).timeout(
            const Duration(seconds: 30),
          );
      final text = await response.stream.bytesToString();
      dynamic decoded;
      try {
        decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      } catch (_) {
        decoded = <String, dynamic>{};
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? '${decoded['message'] ?? 'Yêu cầu thất bại'}'
            : 'Yêu cầu thất bại';
        if (response.statusCode == 401 && auth) {
          await clearToken();
        }
        throw ApiException(response.statusCode, message);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
          0, 'Không thể kết nối máy chủ. Vui lòng thử lại.');
    }
  }
}
