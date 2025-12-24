import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class SetExternalUserIdUseCase
    implements UseCase<Unit, SetExternalUserIdParams> {
  final NotificationRepository repository;

  SetExternalUserIdUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SetExternalUserIdParams params) async {
    return await repository.setExternalUserId(params.userId);
  }
}

class SetExternalUserIdParams extends Equatable {
  final String userId;

  const SetExternalUserIdParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
