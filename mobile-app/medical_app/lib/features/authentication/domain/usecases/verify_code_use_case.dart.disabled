import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String email,
    required int verificationCode,
    required VerificationCodeType codeType,
  }) async {
    return await repository.verifyCode(
      email: email,
      verificationCode: verificationCode,
      codeType: codeType,
    );
  }
}