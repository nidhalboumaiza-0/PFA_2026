part of 'verify_code_bloc.dart';

abstract class VerifyCodeEvent extends Equatable {
  const VerifyCodeEvent();

  @override
  List<Object> get props => [];
}

class VerifyCodeSubmitted extends VerifyCodeEvent {
  final String email;
  final int verificationCode;
  final VerificationCodeType codeType;

  const VerifyCodeSubmitted({
    required this.email,
    required this.verificationCode,
    required this.codeType,
  });

  @override
  List<Object> get props => [email, verificationCode, codeType];
}