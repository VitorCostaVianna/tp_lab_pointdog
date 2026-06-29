import 'pet.dart';
import 'service.dart';

class Appointment {
  final String id;
  final String status;
  final String clientId;
  final String? clientName;
  final String petId;
  final String providerId;
  final String serviceId;
  final DateTime scheduledAt;
  final String? notes;
  final Pet? pet;
  final Service? service;

  const Appointment({
    required this.id,
    required this.status,
    required this.clientId,
    this.clientName,
    required this.petId,
    required this.providerId,
    required this.serviceId,
    required this.scheduledAt,
    this.notes,
    this.pet,
    this.service,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    status: json['status'] as String,
    clientId: json['clientId'] as String,
    clientName: (json['client'] as Map<String, dynamic>?)?['name'] as String?,
    petId: json['petId'] as String,
    providerId: json['providerId'] as String,
    serviceId: json['serviceId'] as String,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    notes: json['notes'] as String?,
    pet: json['pet'] != null
        ? Pet.fromJson(json['pet'] as Map<String, dynamic>)
        : null,
    service: json['service'] != null
        ? Service.fromJson(json['service'] as Map<String, dynamic>)
        : null,
  );

  Appointment copyWith({String? status}) => Appointment(
    id: id, status: status ?? this.status, clientId: clientId,
    clientName: clientName, petId: petId, providerId: providerId,
    serviceId: serviceId, scheduledAt: scheduledAt, notes: notes,
    pet: pet, service: service,
  );

  bool get canCancel => status == 'PENDENTE' || status == 'CONFIRMADO';
}
