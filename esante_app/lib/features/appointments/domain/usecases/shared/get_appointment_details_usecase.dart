import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetAppointmentDetailsUseCase
    implements UseCase<AppointmentEntity, GetAppointmentDetailsParams> {
  final AppointmentRepository repository;

  GetAppointmentDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      GetAppointmentDetailsParams params) {
    return repository.getAppointmentDetails(
      appointmentId: params.appointmentId,
    );
  }
}

class GetAppointmentDetailsParams extends Equatable {
  final String appointmentId;

  const GetAppointmentDetailsParams({
    required this.appointmentId,
  });

  @override
  List<Object?> get props => [appointmentId];
}
