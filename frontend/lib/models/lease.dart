import 'unit.dart';

class Lease {
  final int? id;
  final int unitId;
  final int tenantId;
  final String? startDate;
  final String? endDate;
  final double rentAmount;
  final String status;
  final String? terms;
  final Unit? unit;
  final String? tenantName; // from nested tenant object
  final String? tenantEmail;

  Lease({
    this.id,
    required this.unitId,
    required this.tenantId,
    this.startDate,
    this.endDate,
    required this.rentAmount,
    required this.status,
    this.terms,
    this.unit,
    this.tenantName,
    this.tenantEmail,
  });

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'],
      unitId: json['unit_id'],
      tenantId: json['tenant_id'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      rentAmount: double.parse(json['rent_amount'].toString()),
      status: json['status'],
      terms: json['terms'],
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      tenantName: json['tenant'] != null ? json['tenant']['name'] : null,
      tenantEmail: json['tenant'] != null ? json['tenant']['email'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'tenant_id': tenantId,
      'start_date': startDate,
      'end_date': endDate,
      'rent_amount': rentAmount,
      'status': status,
      'terms': terms,
    };
  }
}
