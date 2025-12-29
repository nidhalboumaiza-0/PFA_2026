import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../presentation/bloc/doctor/doctor_appointment_bloc.dart';
import '../../repositories/appointment_repository.dart';

class BulkSetAvailabilityUseCase
    implements UseCase<Map<String, dynamic>, BulkSetAvailabilityParams> {
  final AppointmentRepository repository;

  BulkSetAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      BulkSetAvailabilityParams params) {
    return repository.bulkSetAvailability(
      availabilities: params.availabilities,
      skipExisting: params.skipExisting,
    );
  }
}

class BulkSetAvailabilityParams extends Equatable {
  final List<AvailabilityEntry> availabilities;
  final bool skipExisting;

  const BulkSetAvailabilityParams({
    required this.availabilities,
    this.skipExisting = true,
  });

  @override
  List<Object?> get props => [availabilities, skipExisting];
}
