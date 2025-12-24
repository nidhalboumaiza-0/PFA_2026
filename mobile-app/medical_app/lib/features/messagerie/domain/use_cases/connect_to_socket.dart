import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

class ConnectToSocketParams extends Equatable {
  final bool forceReconnect;

  const ConnectToSocketParams({this.forceReconnect = false});

  @override
  List<Object?> get props => [forceReconnect];
}

class ConnectToSocket implements UseCase<bool, ConnectToSocketParams> {
  final ConversationRepository repository;

  ConnectToSocket(this.repository);

  @override
  Future<Either<Failure, bool>> call(ConnectToSocketParams params) {
    return repository.connectToSocket(forceReconnect: params.forceReconnect);
  }
}
