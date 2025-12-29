import '../../domain/entities/session_entity.dart';

class SessionModel extends SessionEntity {
  const SessionModel({
    required super.sessionId,
    required super.device,
    required super.ip,
    required super.createdAt,
    required super.lastActivity,
    required super.isCurrent,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'] ?? '',
      device: json['device'] ?? 'Unknown device',
      ip: json['ip'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'device': device,
      'ip': ip,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}
