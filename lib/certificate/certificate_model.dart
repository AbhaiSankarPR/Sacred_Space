import 'dart:convert';

enum CertificateType {
  BAPTISM,
  MARRIAGE,
  MARRIAGE_PREPARATION,
  NIHIL_OBSTAT;

  String toJson() => name;

  static CertificateType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'MARRIAGE':
        return CertificateType.MARRIAGE;
      case 'MARRIAGE_PREPARATION':
        return CertificateType.MARRIAGE_PREPARATION;
      case 'NIHIL_OBSTAT':
        return CertificateType.NIHIL_OBSTAT;
      case 'BAPTISM':
      default:
        return CertificateType.BAPTISM;
    }
  }

  String get displayName {
    switch (this) {
      case CertificateType.BAPTISM:
        return 'Baptism';
      case CertificateType.MARRIAGE:
        return 'Marriage';
      case CertificateType.MARRIAGE_PREPARATION:
        return 'Identification Letter';
      case CertificateType.NIHIL_OBSTAT:
        return 'Nihil Obstat';
    }
  }
}

enum CertificateStatus {
  PENDING,
  APPROVED,
  REJECTED;

  static CertificateStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'APPROVED':
        return CertificateStatus.APPROVED;
      case 'REJECTED':
        return CertificateStatus.REJECTED;
      case 'PENDING':
      default:
        return CertificateStatus.PENDING;
    }
  }
}

class CertificateRequest {
  final String id;
  final CertificateType type;
  final Map<String, dynamic> details;
  final CertificateStatus status;
  final String? rejectionReason;
  final String churchId;
  final String userId;
  final String? approvedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? requesterName;

  CertificateRequest({
    required this.id,
    required this.type,
    required this.details,
    required this.status,
    this.rejectionReason,
    required this.churchId,
    required this.userId,
    this.approvedById,
    required this.createdAt,
    required this.updatedAt,
    this.requesterName,
  });

  factory CertificateRequest.fromJson(Map<String, dynamic> json) {
    String? reqName;
    if (json['user'] != null) {
      if (json['user']['profile'] != null) {
        reqName = json['user']['profile']['name'];
      }
      reqName ??= json['user']['name'];
    }

    return CertificateRequest(
      id: json['id'] ?? '',
      type: CertificateType.fromString(json['type'] ?? 'BAPTISM'),
      details:
          json['details'] is String
              ? jsonDecode(json['details'])
              : (json['details'] as Map<String, dynamic>? ?? {}),
      status: CertificateStatus.fromString(json['status'] ?? 'PENDING'),
      rejectionReason: json['rejectionReason'],
      churchId: json['churchId'] ?? '',
      userId: json['userId'] ?? '',
      approvedById: json['approvedById'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      requesterName: reqName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'details': details,
    'status': status.name,
    'rejectionReason': rejectionReason,
    'churchId': churchId,
    'userId': userId,
    'approvedById': approvedById,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'requesterName': requesterName,
  };
}
