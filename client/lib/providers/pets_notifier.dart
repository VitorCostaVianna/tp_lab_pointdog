import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../repositories/pets_repository.dart';

class PetsNotifier extends ChangeNotifier {
  final PetsRepository _repo = PetsRepository();

  List<Pet> _pets = [];
  bool _loading = false;
  String? _error;

  List<Pet> get pets => _pets;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pets = await _repo.listMyPets();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addPet({
    required String name,
    required String breed,
    required String size,
    String? notes,
  }) async {
    try {
      final pet = await _repo.create(name: name, breed: breed, size: size, notes: notes);
      _pets = [pet, ..._pets];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
