import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]) : super();

  @override
  List<Object> get props => [];
}

// General failures
class ServerFailure extends Failure {
  final String? message;

  const ServerFailure({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

class CacheFailure extends Failure {
  final String? message;

  const CacheFailure({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

class OfflineFailure extends Failure {}

// Auth failures
class AuthFailure extends Failure {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class UnauthorizedFailure extends Failure {}

class NotFoundFailure extends Failure {
  final String message;

  const NotFoundFailure({required this.message});

  @override
  List<Object> get props => [message];
}
