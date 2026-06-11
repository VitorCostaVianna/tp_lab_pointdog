import 'package:flutter/foundation.dart';
import '../models/service.dart';
import '../repositories/services_repository.dart';

class ServicesNotifier extends ChangeNotifier {
  final ServicesRepository _repo = ServicesRepository();

  List<Service> _services = [];
  Service? _selected;
  bool _loading = false;
  String? _error;

  List<Service> get services => _services;
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
}
