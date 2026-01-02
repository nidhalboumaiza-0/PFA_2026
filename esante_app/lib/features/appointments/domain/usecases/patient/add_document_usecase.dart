import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/document_entity.dart';
import '../../repositories/appointment_repository.dart';

/// Use case to add a document to an appointment
class AddDocumentToAppointmentUseCase 
    implements UseCase<AppointmentDocumentEntity, AddDocumentParams> {
  final AppointmentRepository repository;

  AddDocumentToAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentDocumentEntity>> call(AddDocumentParams params) {
    return repository.addDocumentToAppointment(
      appointmentId: params.appointmentId,
      name: params.name,
      url: params.url,
      type: params.type,
      description: params.description,
    );
  }
}

class AddDocumentParams extends Equatable {
  final String appointmentId;
  final String name;
  final String url;
  final DocumentType type;
  final String? description;

  const AddDocumentParams({
    required this.appointmentId,
    required this.name,
    required this.url,
    this.type = DocumentType.other,
    this.description,
  });

  @override
  List<Object?> get props => [appointmentId, name, url, type, description];
}
