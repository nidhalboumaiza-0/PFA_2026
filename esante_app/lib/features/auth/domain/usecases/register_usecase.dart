import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<String, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      role: params.role,
      profileData: params.profileData,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String role;
  final Map<String, dynamic>? profileData;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.role,
    this.profileData,
  });

  @override
  List<Object?> get props => [email, password, role, profileData];
}
