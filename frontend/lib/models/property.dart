class Property {
  final int? id;
  final String name;
  final String location;
  final int floorsCount;
  final int? landlordId;

  Property({
    this.id,
    required this.name,
    required this.location,
    required this.floorsCount,
    this.landlordId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      floorsCount: int.parse(json['floors_count'].toString()),
      landlordId: int.parse(json['landlord_id'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'floors_count': floorsCount,
      'landlord_id': landlordId,
    };
  }
}
