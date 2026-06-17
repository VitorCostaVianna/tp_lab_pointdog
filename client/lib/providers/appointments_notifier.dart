import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/auth/auth_storage.dart';
import '../core/network/websocket_service.dart';
import '../models/appointment.dart';
import '../repositories/appointments_repository.dart';

class AppointmentsNotifier extends ChangeNotifier {
  final AppointmentsRepository _repo = AppointmentsRepository();
  final WebSocketService _ws = WebSocketService();

  List<Appointment> _appointments = [];
  Appointment? _selected;
  bool _loading = false;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  List<Appointment> get appointments => _appointments;
  Appointment? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  List<Appointment> get pending =>
      _appointments.where((a) => a.status == 'PENDENTE').toList();
  List<Appointment> get active =>
      _appointments.where((a) => a.status == 'CONFIRMADO').toList();
  List<Appointment> get history => _appointments
      .where((a) => a.status == 'CANCELADO' || a.status == 'CONCLUIDO')
      .toList();

  void startListening() {
    _wsSub?.cancel();
    _wsSub = _ws.stream.listen((event) {
      final eventType = event['eventType'] as String?;
      final payload = event['payload'] as Map<String, dynamic>?;
      if (payload == null) return;

      if (eventType == 'appointment.status_changed') {
        final appointmentId = payload['appointmentId'] as String?;
        final newStatus = payload['newStatus'] as String?;
        if (appointmentId == null || newStatus == null) return;

        _appointments = _appointments
            .map((a) => a.id == appointmentId ? a.copyWith(status: newStatus) : a)
            .toList();

        if (_selected?.id == appointmentId) {
          _selected = _selected!.copyWith(status: newStatus);
        }
        notifyListeners();
        return;
      }

      if (eventType == 'appointment.created') {
        final auth = AuthStorage();
        final providerId = payload['providerId'] as String?;
        if (auth.role == 'PRESTADOR' && providerId == auth.userId) {
          // O payload do evento carrega apenas IDs; recarregamos via REST
          // para obter os dados enriquecidos (pet, serviço).
          loadAll();
        }
        return;
      }
    });
  }

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _appointments = await _repo.listMine();
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

  Future<bool> create({
    required String petId,
    required String serviceId,
    required String providerId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    try {
      final appointment = await _repo.create(
        petId: petId,
        serviceId: serviceId,
        providerId: providerId,
        scheduledAt: scheduledAt,
        notes: notes,
      );
      _appointments = [appointment, ..._appointments];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> _patch(String id, String status) async {
    try {
      final updated = await _repo.updateStatus(id, status);
      _appointments =
          _appointments.map((a) => a.id == id ? updated : a).toList();
      _selected = _selected?.id == id ? updated : _selected;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancel(String id) => _patch(id, 'CANCELADO');
  Future<bool> confirm(String id) => _patch(id, 'CONFIRMADO');
  Future<bool> complete(String id) => _patch(id, 'CONCLUIDO');
  Future<bool> decline(String id) => _patch(id, 'CANCELADO');

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
