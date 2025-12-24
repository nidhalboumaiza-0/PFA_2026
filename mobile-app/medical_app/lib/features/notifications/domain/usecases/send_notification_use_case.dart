import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class SendNotificationUseCase implements UseCase<Unit, SendNotificationParams> {
  final NotificationRepository repository;

  SendNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SendNotificationParams params) async {
    return await repository.sendNotification(
      title: params.title,
      body: params.body,
      senderId: params.senderId,
      recipientId: params.recipientId,
      type: params.type,
      appointmentId: params.appointmentId,
      prescriptionId: params.prescriptionId,
      data: params.data,
    );
  }
}

class SendNotificationParams extends Equatable {
  final String title;
  final String body;
  final String senderId;
  final String recipientId;
  final NotificationType type;
  final String? appointmentId;
  final String? prescriptionId;
  final Map<String, dynamic>? data;

  const SendNotificationParams({
    required this.title,
    required this.body,
    required this.senderId,
    required this.recipientId,
    required this.type,
    this.appointmentId,
    this.prescriptionId,
    this.data,
  });

  @override
  List<Object?> get props => [
    title,
    body,
    senderId,
    recipientId,
    type,
    appointmentId,
    prescriptionId,
    data,
  ];
}
