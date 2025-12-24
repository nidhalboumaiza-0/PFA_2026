part of 'verify_code_bloc.dart';

abstract class VerifyCodeState extends Equatable {
  const VerifyCodeState();

  @override
  List<Object> get props => [];
}

class VerifyCodeInitial extends VerifyCodeState {}

class VerifyCodeLoading extends VerifyCodeState {}

class VerifyCodeSuccess extends VerifyCodeState {
  final int verificationCode;

  const VerifyCodeSuccess({required this.verificationCode});

  @override
  List<Object> get props => [verificationCode];
}

class VerifyCodeError extends VerifyCodeState {
  final String message;

  const VerifyCodeError({required this.message});

  @override
  List<Object> get props => [message];
}