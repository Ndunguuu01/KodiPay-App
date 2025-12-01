class Bill {
  final int? id;
  final int unitId;
  final int tenantId;
  final String type;
  final double amount;
  final String dueDate;
  final String status;
  final String? description;

  Bill({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.description,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      unitId: json['unit_id'],
      tenantId: json['tenant_id'],
      type: json['type'],
      amount: double.parse(json['amount'].toString()),
      dueDate: json['due_date'],
      status: json['status'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'tenant_id': tenantId,
      'type': type,
      'amount': amount,
      'due_date': dueDate,
      'status': status,
      'description': description,
    };
  }
}
