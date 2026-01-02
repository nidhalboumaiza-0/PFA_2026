import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

/// Use case to send a file message
class SendFileMessageUseCase
    implements UseCase<MessageEntity, SendFileMessageParams> {
  final MessagingRepository repository;

  SendFileMessageUseCase(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendFileMessageParams params) {
    return repository.sendFileMessage(
      conversationId: params.conversationId,
      file: params.file,
      caption: params.caption,
    );
  }
}

/// Parameters for SendFileMessageUseCase
class SendFileMessageParams extends Equatable {
  final String conversationId;
  final File file;
  final String? caption;

  const SendFileMessageParams({
    required this.conversationId,
    required this.file,
    this.caption,
  });

  @override
  List<Object?> get props => [conversationId, file.path, caption];
}
