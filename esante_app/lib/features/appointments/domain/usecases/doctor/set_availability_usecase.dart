import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/time_slot_entity.dart';
import '../../repositories/appointment_repository.dart';

class SetAvailabilityUseCase
    implements UseCase<TimeSlotEntity, SetAvailabilityParams> {
  final AppointmentRepository repository;

  SetAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, TimeSlotEntity>> call(SetAvailabilityParams params) {
    return repository.setAvailability(
      date: params.date,
      timeSlots: params.timeSlots,
      specialNotes: params.specialNotes,
    );
  }
}

// SetAvailabilityParams is defined in time_slot_entity.dart
