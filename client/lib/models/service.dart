class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String providerId;
  final String? providerName;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.providerId,
    this.providerName,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toDouble(),
    durationMinutes: json['durationMinutes'] as int,
    providerId: json['providerId'] as String,
    providerName: (json['provider'] as Map<String, dynamic>?)?['name'] as String?,
  );
}
