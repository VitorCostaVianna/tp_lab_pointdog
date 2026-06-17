import 'package:dio/dio.dart';
import '../core/network/http_client.dart';
import '../models/appointment.dart';

class AppointmentsRepository {
  final Dio _dio = AppHttpClient().dio;

  Future<List<Appointment>> listMine() async {
    final response = await _dio.get('/appointments');
    final data = response.data as List<dynamic>;
    return data.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Appointment> getById(String id) async {
    final response = await _dio.get('/appointments/$id');
    return Appointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Appointment> create({
    required String petId,
    required String serviceId,
    required String providerId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final response = await _dio.post('/appointments', data: {
      'petId': petId,
      'serviceId': serviceId,
      'providerId': providerId,
      'scheduledAt': scheduledAt.toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Appointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Appointment> updateStatus(String id, String status) async {
    final response = await _dio.patch('/appointments/$id/status', data: {'status': status});
    return Appointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Appointment> cancel(String id) => updateStatus(id, 'CANCELADO');
}
