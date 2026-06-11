class Pet {
  final String id;
  final String name;
  final String breed;
  final String size;
  final String ownerId;
  final String? notes;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.size,
    required this.ownerId,
    this.notes,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'] as String,
    name: json['name'] as String,
    breed: json['breed'] as String,
    size: json['size'] as String,
    ownerId: json['ownerId'] as String,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'breed': breed,
    'size': size,
    if (notes != null) 'notes': notes,
  };
}
