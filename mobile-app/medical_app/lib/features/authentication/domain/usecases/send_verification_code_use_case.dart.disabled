import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

import '../../data/data sources/auth_remote_data_source.dart';

class SendVerificationCodeUseCase {
  final AuthRepository repository;

  SendVerificationCodeUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String email,
    required VerificationCodeType codeType,
  }) async {
    return await repository.sendVerificationCode(
      email: email,
      codeType: codeType,
    );
  }
}