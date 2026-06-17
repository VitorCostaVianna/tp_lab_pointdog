import 'package:flutter/foundation.dart';
import '../models/service.dart';
import '../repositories/services_repository.dart';

class ServicesNotifier extends ChangeNotifier {
  final ServicesRepository _repo = ServicesRepository();

  List<Service> _services = [];
  List<Service> _myServices = [];
  Service? _selected;
  bool _loading = false;
  String? _error;

  List<Service> get services => _services;
  List<Service> get myServices => _myServices;
  Service? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _services = await _repo.listAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine(String providerId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _myServices = await _repo.listMine(providerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadById(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _repo.getById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createService({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      final service = await _repo.create(
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
      );
      _myServices = [service, ..._myServices];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateService(
    String id, {
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      final updated = await _repo.update(
        id,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
      );
      _myServices = _myServices.map((s) => s.id == id ? updated : s).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteService(String id) async {
    try {
      await _repo.delete(id);
      _myServices = _myServices.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
