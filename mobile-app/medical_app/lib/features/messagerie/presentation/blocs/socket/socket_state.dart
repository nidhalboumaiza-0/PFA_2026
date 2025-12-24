part of 'socket_bloc.dart';

abstract class SocketState extends Equatable {
  const SocketState();

  @override
  List<Object> get props => [];
}

class SocketDisconnected extends SocketState {}

class SocketConnecting extends SocketState {}

class SocketConnected extends SocketState {}

class SocketReconnecting extends SocketState {}

class SocketError extends SocketState {
  final String message;

  const SocketError({required this.message});

  @override
  List<Object> get props => [message];
}
