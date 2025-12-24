import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class SaveOneSignalPlayerIdUseCase
    implements UseCase<Unit, SaveOneSignalPlayerIdParams> {
  final NotificationRepository repository;

  SaveOneSignalPlayerIdUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SaveOneSignalPlayerIdParams params) async {
    return await repository.saveOneSignalPlayerId(params.userId);
  }
}

class SaveOneSignalPlayerIdParams extends Equatable {
  final String userId;

  const SaveOneSignalPlayerIdParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
