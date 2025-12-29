import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/time_slot_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetDoctorAvailabilityUseCase
    implements UseCase<List<TimeSlotEntity>, GetDoctorAvailabilityParams> {
  final AppointmentRepository repository;

  GetDoctorAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, List<TimeSlotEntity>>> call(
      GetDoctorAvailabilityParams params) {
    return repository.viewDoctorAvailability(
      doctorId: params.doctorId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetDoctorAvailabilityParams extends Equatable {
  final String doctorId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetDoctorAvailabilityParams({
    required this.doctorId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [doctorId, startDate, endDate];
}
