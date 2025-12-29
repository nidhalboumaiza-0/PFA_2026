import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/time_slot_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetDoctorScheduleUseCase
    implements UseCase<List<TimeSlotEntity>, GetDoctorScheduleParams> {
  final AppointmentRepository repository;

  GetDoctorScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, List<TimeSlotEntity>>> call(
      GetDoctorScheduleParams params) {
    return repository.getDoctorAvailability(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetDoctorScheduleParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetDoctorScheduleParams({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
