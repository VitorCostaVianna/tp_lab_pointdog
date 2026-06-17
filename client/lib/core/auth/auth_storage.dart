import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static final AuthStorage _instance = AuthStorage._();
  factory AuthStorage() => _instance;
  AuthStorage._();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? get token => _prefs?.getString(_tokenKey);
  String? get userId => _prefs?.getString(_userIdKey);
  String? get role => _prefs?.getString(_roleKey);
  bool get isLoggedIn => token != null;

  Future<void> save({
    required String token,
    required String userId,
    required String role,
  }) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userIdKey, userId);
    await _prefs?.setString(_roleKey, role);
  }

  Future<void> clear() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_roleKey);
  }
}
