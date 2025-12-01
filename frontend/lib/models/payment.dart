class Payment {
  final int? id;
  final int tenantId;
  final int unitId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionCode;
  final DateTime? createdAt;
  final String? phone;

  Payment({
    this.id,
    required this.tenantId,
    required this.unitId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionCode,
    this.createdAt,
    this.phone,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      tenantId: int.parse(json['tenant_id'].toString()),
      unitId: int.parse(json['unit_id'].toString()),
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'],
      status: json['status'],
      transactionCode: json['transaction_code'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'unit_id': unitId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_code': transactionCode,
      'phone': phone,
    };
  }
}
