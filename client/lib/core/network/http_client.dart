import 'package:dio/dio.dart';
import '../auth/auth_storage.dart';
import '../config/app_config.dart';

class AppHttpClient {
  static final AppHttpClient _instance = AppHttpClient._();
  factory AppHttpClient() => _instance;
  AppHttpClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthStorage().token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  late final Dio _dio;
  Dio get dio => _dio;
}
