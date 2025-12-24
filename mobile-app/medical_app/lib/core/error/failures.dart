import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = ''});

  @override
  List<Object> get props => [message];
}

class OfflineFailure extends Failure {
  @override
  String get message => 'offline_failure_message';
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'})
    : super(message: message);
}

class EmptyCacheFailure extends Failure {
  @override
  String get message => 'empty_cache_failure_message';
}

class ServerMessageFailure extends Failure {
  final String customMessage;

  ServerMessageFailure(this.customMessage);

  @override
  String get message => customMessage;
}

class UnauthorizedFailure extends Failure {
  @override
  String get message => 'unauthorized_failure_message';
}

class TimeoutFailure extends Failure {
  @override
  String get message => 'timeout_failure_message';
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed'])
    : super(message: message);
}

class UsedEmailOrPhoneNumberFailure extends Failure {
  final String? customMessage;

  UsedEmailOrPhoneNumberFailure([this.customMessage]);

  @override
  String get message => customMessage ?? 'email_or_phone_number_used';
}

class YouHaveToCreateAccountAgainFailure extends Failure {
  final String? customMessage;

  YouHaveToCreateAccountAgainFailure([this.customMessage]);

  @override
  String get message => customMessage ?? 'create_account_again';
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache failure occurred'})
    : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network failure occurred'})
    : super(message: message);
}

class FileFailure extends Failure {
  const FileFailure({String message = 'File operation failure occurred'})
    : super(message: message);
}
