class MaintenanceRequest {
  final int? id;
  final int unitId;
  final int tenantId;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String issueType;
  final String priority;
  final String? unitNumber;

  MaintenanceRequest({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.description,
    required this.issueType,
    this.priority = 'medium',
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.unitNumber,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'],
      unitId: json['unit_id'],
      tenantId: json['tenant_id'],
      description: json['description'],
      issueType: json['issue_type'] ?? 'other',
      priority: json['priority'] ?? 'medium',
      status: json['status'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      unitNumber: json['unit'] != null ? json['unit']['unit_number'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'tenant_id': tenantId,
      'description': description,
      'issue_type': issueType,
      'priority': priority,
      'status': status,
    };
  }
}
