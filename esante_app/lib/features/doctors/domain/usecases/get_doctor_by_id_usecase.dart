import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/doctor_entity.dart';
import '../repositories/doctor_repository.dart';

class GetDoctorByIdUseCase implements UseCase<DoctorEntity, GetDoctorParams> {
  final DoctorRepository repository;

  GetDoctorByIdUseCase(this.repository);

  @override
  Future<Either<Failure, DoctorEntity>> call(GetDoctorParams params) {
    return repository.getDoctorById(params.doctorId);
  }
}

class GetDoctorParams extends Equatable {
  final String doctorId;

  const GetDoctorParams({required this.doctorId});

  @override
  List<Object?> get props => [doctorId];
}
