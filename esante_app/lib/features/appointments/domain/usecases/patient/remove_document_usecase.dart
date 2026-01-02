import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/appointment_repository.dart';

/// Use case to remove a document from an appointment
class RemoveDocumentUseCase implements UseCase<void, RemoveDocumentParams> {
  final AppointmentRepository repository;

  RemoveDocumentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveDocumentParams params) {
    return repository.removeDocumentFromAppointment(
      appointmentId: params.appointmentId,
      documentId: params.documentId,
    );
  }
}

class RemoveDocumentParams extends Equatable {
  final String appointmentId;
  final String documentId;

  const RemoveDocumentParams({
    required this.appointmentId,
    required this.documentId,
  });

  @override
  List<Object?> get props => [appointmentId, documentId];
}
