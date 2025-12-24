import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/connect_to_socket.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/message/message_bloc.dart';

part 'socket_event.dart';
part 'socket_state.dart';

class SocketBloc extends Bloc<SocketEvent, SocketState> {
  final ConnectToSocket connectToSocket;
  final ConversationRepository repository;
  final MessageBloc messageBloc;

  StreamSubscription? _messageStreamSubscription;
  StreamSubscription? _typingStreamSubscription;
  StreamSubscription? _readReceiptStreamSubscription;
  StreamSubscription? _connectionStatusSubscription;

  SocketBloc({
    required this.connectToSocket,
    required this.repository,
    required this.messageBloc,
  }) : super(SocketDisconnected()) {
    on<ConnectSocketEvent>(_onConnectSocket);
    on<DisconnectSocketEvent>(_onDisconnectSocket);
    on<SocketConnectionChangedEvent>(_onConnectionChanged);
  }

  Future<void> _onConnectSocket(
    ConnectSocketEvent event,
    Emitter<SocketState> emit,
  ) async {
    emit(SocketConnecting());

    final result = await connectToSocket(
      ConnectToSocketParams(forceReconnect: event.forceReconnect),
    );

    result.fold(
      (failure) {
        emit(SocketError(message: 'Failed to connect to socket'));
      },
      (success) {
        emit(SocketConnected());

        // Listen to real-time message events
        _listenToMessages();
        _listenToTypingIndicators();
        _listenToReadReceipts();
        _listenToConnectionStatus();
      },
    );
  }

  Future<void> _onDisconnectSocket(
    DisconnectSocketEvent event,
    Emitter<SocketState> emit,
  ) async {
    _cancelSubscriptions();

    final result = await repository.disconnectFromSocket();

    result.fold(
      (failure) {
        emit(SocketError(message: 'Failed to disconnect socket properly'));
      },
      (success) {
        emit(SocketDisconnected());
      },
    );
  }

  void _onConnectionChanged(
    SocketConnectionChangedEvent event,
    Emitter<SocketState> emit,
  ) {
    if (event.isConnected) {
      emit(SocketConnected());
      debugPrint('SocketBloc: Connection restored');
    } else {
      emit(SocketReconnecting());
      debugPrint('SocketBloc: Connection lost, attempting to reconnect...');
    }
  }

  void _listenToMessages() {
    _messageStreamSubscription?.cancel();
    _messageStreamSubscription = repository.messageStream.listen((message) {
      messageBloc.add(MessageReceivedEvent(message: message));
    });
  }

  void _listenToTypingIndicators() {
    _typingStreamSubscription?.cancel();
    _typingStreamSubscription = repository.typingStream.listen((data) {
      final userId = data['userId'] as String;
      final isTyping = data['isTyping'] as bool;

      messageBloc.add(TypingIndicatorEvent(isTyping: isTyping, userId: userId));
    });
  }

  void _listenToReadReceipts() {
    _readReceiptStreamSubscription?.cancel();
    _readReceiptStreamSubscription = repository.readReceiptStream.listen((
      data,
    ) {
      // Handle read receipts if needed
    });
  }

  void _listenToConnectionStatus() {
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = repository.connectionStatusStream.listen((isConnected) {
      add(SocketConnectionChangedEvent(isConnected: isConnected));
    });
  }

  void _cancelSubscriptions() {
    _messageStreamSubscription?.cancel();
    _typingStreamSubscription?.cancel();
    _readReceiptStreamSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
