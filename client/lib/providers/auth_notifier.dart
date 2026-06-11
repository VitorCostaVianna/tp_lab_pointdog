import 'package:flutter/foundation.dart';
import '../core/auth/auth_storage.dart';
import '../core/network/websocket_service.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final AuthStorage _storage = AuthStorage();
  final WebSocketService _ws = WebSocketService();

  AuthStatus _status = AuthStatus.initial;
  String? _error;
  User? _user;

  AuthStatus get status => _status;
  String? get error => _error;
  User? get user => _user;
  bool get isLoggedIn => _storage.isLoggedIn;

  Future<void> initialize() async {
    await _storage.init();
    if (_storage.isLoggedIn) {
      _status = AuthStatus.authenticated;
      _ws.connect();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.login(email, password);
      final token = data['token'] as String;
      final userMap = data['user'] as Map<String, dynamic>;
      _user = User.fromJson({...userMap, 'email': email});
      await _storage.save(token: token, userId: _user!.id);
      _status = AuthStatus.authenticated;
      _ws.connect();
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _repo.register(name, email, password);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _ws.disconnect();
    await _storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'Ocorreu um erro. Tente novamente.';
  }
}
