import 'package:dio/dio.dart';
import '../core/network/http_client.dart';
import '../models/user.dart';

class AuthRepository {
  final Dio _dio = AppHttpClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<User> register(
    String name,
    String email,
    String password, {
    String role = 'CLIENTE',
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
