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

  Future<List<Service>> listMine(String providerId) async {
    final response = await _dio.get('/services', queryParameters: {'providerId': providerId});
    final data = response.data as List<dynamic>;
    return data.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Service> getById(String id) async {
    final response = await _dio.get('/services/$id');
    return Service.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Service> create({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
  }) async {
    final response = await _dio.post('/services', data: {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
    });
    return Service.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Service> update(
    String id, {
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
  }) async {
    final response = await _dio.put('/services/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    });
    return Service.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/services/$id');
  }
}
