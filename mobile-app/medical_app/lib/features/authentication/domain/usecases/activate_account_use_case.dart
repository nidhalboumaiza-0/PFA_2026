// import 'package:dartz/dartz.dart';
// import 'package:medical_app/core/error/failures.dart';
// import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';
//
// class ActivateAccountUseCase {
//   final AuthRepository repository;
//
//   ActivateAccountUseCase(this.repository);
//
//   Future<Either<Failure, Unit>> call({
//     required String email,
//     required int verificationCode,
//   }) async {
//     return await repository.activateAccount(
//       email: email,
//       verificationCode: verificationCode,
//     );
//   }
// }