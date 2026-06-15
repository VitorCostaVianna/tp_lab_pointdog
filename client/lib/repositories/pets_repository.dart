import 'package:dio/dio.dart';
import '../core/network/http_client.dart';
import '../models/pet.dart';

class PetsRepository {
  final Dio _dio = AppHttpClient().dio;

  Future<List<Pet>> listMyPets() async {
    final response = await _dio.get('/pets');
    final data = response.data as List<dynamic>;
    return data.map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Pet> create({
    required String name,
    required String breed,
    required String size,
    String? notes,
  }) async {
    final response = await _dio.post('/pets', data: {
      'name': name,
      'breed': breed,
      'size': size,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Pet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Pet> update({
    required String id,
    required String name,
    required String breed,
    required String size,
    String? notes,
  }) async {
    final response = await _dio.put('/pets/$id', data: {
      'name': name,
      'breed': breed,
      'size': size,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Pet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/pets/$id');
  }
}
