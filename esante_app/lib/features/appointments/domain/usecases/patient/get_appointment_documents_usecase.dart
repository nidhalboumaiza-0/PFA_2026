import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/document_entity.dart';
import '../../repositories/appointment_repository.dart';

/// Use case to get all documents attached to an appointment
class GetAppointmentDocumentsUseCase 
    implements UseCase<List<AppointmentDocumentEntity>, GetDocumentsParams> {
  final AppointmentRepository repository;

  GetAppointmentDocumentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentDocumentEntity>>> call(GetDocumentsParams params) {
    return repository.getAppointmentDocuments(
      appointmentId: params.appointmentId,
    );
  }
}

class GetDocumentsParams extends Equatable {
  final String appointmentId;

  const GetDocumentsParams({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}
