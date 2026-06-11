import 'package:dio/dio.dart';
import '../core/network/http_client.dart';
import '../models/service.dart';

class ServicesRepository {
  final Dio _dio = AppHttpClient().dio;

  Future<List<Service>> listAll() async {
    final response = await _dio.get('/services');
    final data = response.data as List<dynamic>;
    return data.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Service> getById(String id) async {
    final response = await _dio.get('/services/$id');
    return Service.fromJson(response.data as Map<String, dynamic>);
  }
}
