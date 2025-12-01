class Unit {
  final int? id;
  final String unitNumber;
  final double rentAmount;
  final String status; // 'vacant' or 'occupied'
  final int? tenantId;
  final String? tenantName;
  final int? propertyId;
  final int? floorNumber;
  final String? roomNumber;

  Unit({
    this.id,
    required this.propertyId,
    required this.unitNumber,
    required this.rentAmount,
    required this.status,
    this.tenantId,
    this.tenantName,
    this.floorNumber,
    this.roomNumber,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      propertyId: json['property_id'],
      unitNumber: json['unit_number'],
      rentAmount: double.parse(json['rent_amount'].toString()),
      status: json['status'],
      tenantId: json['tenant_id'],
      tenantName: json['tenant'] != null ? json['tenant']['name'] : null,
      floorNumber: json['floor_number'] != null ? int.tryParse(json['floor_number'].toString()) : null,
      roomNumber: json['room_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'unit_number': unitNumber,
      'rent_amount': rentAmount,
      'status': status,
      'tenant_id': tenantId,
      'floor_number': floorNumber,
      'room_number': roomNumber,
    };
  }
}
