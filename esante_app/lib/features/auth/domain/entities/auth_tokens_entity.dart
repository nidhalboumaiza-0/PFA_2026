import 'package:equatable/equatable.dart';

class AuthTokensEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String sessionId;

  const AuthTokensEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, sessionId];
}
