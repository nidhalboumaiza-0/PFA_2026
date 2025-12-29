import 'package:equatable/equatable.dart';

class SessionEntity extends Equatable {
  final String sessionId;
  final String device;
  final String ip;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isCurrent;

  const SessionEntity({
    required this.sessionId,
    required this.device,
    required this.ip,
    required this.createdAt,
    required this.lastActivity,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [
        sessionId,
        device,
        ip,
        createdAt,
        lastActivity,
        isCurrent,
      ];
}
