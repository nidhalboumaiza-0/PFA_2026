part of 'socket_bloc.dart';

abstract class SocketEvent extends Equatable {
  const SocketEvent();

  @override
  List<Object> get props => [];
}

class ConnectSocketEvent extends SocketEvent {
  final bool forceReconnect;

  const ConnectSocketEvent({this.forceReconnect = false});

  @override
  List<Object> get props => [forceReconnect];
}

class DisconnectSocketEvent extends SocketEvent {}

class SocketConnectionChangedEvent extends SocketEvent {
  final bool isConnected;

  const SocketConnectionChangedEvent({required this.isConnected});

  @override
  List<Object> get props => [isConnected];
}
