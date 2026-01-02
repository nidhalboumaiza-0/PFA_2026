import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/messaging_socket_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_messages_read_usecase.dart';
import '../../domain/usecases/send_file_message_usecase.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';

/// BLoC for managing messaging state
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final GetConversationsUseCase getConversationsUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final CreateConversationUseCase createConversationUseCase;
  final MarkMessagesReadUseCase markMessagesReadUseCase;
  final SendFileMessageUseCase sendFileMessageUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MessagingSocketService? messagingSocketService;

  // Cache for loaded data
  List<ConversationEntity> _conversations = [];
  Map<String, List<MessageEntity>> _messagesCache = {};
  int _unreadCount = 0;

  // Socket subscription
  StreamSubscription<MessagingSocketEvent>? _socketSubscription;

  // Current conversation context for typing
  String? _currentConversationId;
  String? _currentReceiverId;

  MessagingBloc({
    required this.getConversationsUseCase,
    required this.getMessagesUseCase,
    required this.createConversationUseCase,
    required this.markMessagesReadUseCase,
    required this.sendFileMessageUseCase,
    required this.getUnreadCountUseCase,
    this.messagingSocketService,
  }) : super(const MessagingInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendFileMessage>(_onSendFileMessage);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<GetUnreadCount>(_onGetUnreadCount);
    on<UpdateUnreadCount>(_onUpdateUnreadCount);
    on<MessageReceived>(_onMessageReceived);
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<UserOnline>(_onUserOnline);
    on<UserOffline>(_onUserOffline);
    on<ClearCurrentConversation>(_onClearCurrentConversation);
    on<ResetMessaging>(_onResetMessaging);

    // Subscribe to socket events
    _subscribeToSocket();
  }

  void _log(String method, String message) {
    print('[MessagingBloc.$method] $message');
  }

  /// Subscribe to socket events
  void _subscribeToSocket() {
    if (messagingSocketService == null) return;

    _socketSubscription = messagingSocketService!.eventStream.listen((event) {
      switch (event.type) {
        case MessagingSocketEventType.newMessage:
          if (event.data != null) {
            add(MessageReceived(messageData: event.data!));
          }
          break;
        case MessagingSocketEventType.userTyping:
          if (event.data != null) {
            add(TypingIndicatorReceived(
              conversationId: event.data!['conversationId'] ?? '',
              userId: event.data!['userId'] ?? '',
              isTyping: true,
            ));
          }
          break;
        case MessagingSocketEventType.userStoppedTyping:
          if (event.data != null) {
            add(TypingIndicatorReceived(
              conversationId: event.data!['conversationId'] ?? '',
              userId: event.data!['userId'] ?? '',
              isTyping: false,
            ));
          }
          break;
        case MessagingSocketEventType.userOnline:
          if (event.data != null) {
            add(UserOnline(userId: event.data!['userId'] ?? ''));
          }
          break;
        case MessagingSocketEventType.userOffline:
          if (event.data != null) {
            add(UserOffline(userId: event.data!['userId'] ?? ''));
          }
          break;
        case MessagingSocketEventType.messagesRead:
          // Refresh messages to update read status
          if (event.data != null && _currentConversationId != null) {
            add(LoadMessages(conversationId: _currentConversationId!, refresh: true));
          }
          break;
        default:
          break;
      }
    });
  }

  /// Get cached conversations
  List<ConversationEntity> get conversations => _conversations;

  /// Get cached unread count
  int get unreadCount => _unreadCount;

  // ============== Conversation Handlers ==============

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onLoadConversations', 'Loading conversations (page: ${event.page}, refresh: ${event.refresh})');

    if (event.refresh || _conversations.isEmpty) {
      emit(const ConversationsLoading());
    }

    final result = await getConversationsUseCase(
      GetConversationsParams(
        type: event.type,
        page: event.page,
        limit: 20,
      ),
    );

    result.fold(
      (failure) {
        _log('_onLoadConversations', 'Failed: ${failure.message}');
        emit(ConversationsError(message: failure.message));
      },
      (conversations) {
        _log('_onLoadConversations', 'Success: ${conversations.length} conversations');

        if (event.refresh || event.page == 1) {
          _conversations = conversations;
        } else {
          _conversations = [..._conversations, ...conversations];
        }

        emit(ConversationsLoaded(
          conversations: _conversations,
          hasMore: conversations.length >= 20,
          currentPage: event.page,
        ));
      },
    );
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onCreateConversation', 'Creating conversation with ${event.recipientId}');

    final result = await createConversationUseCase(
      CreateConversationParams(
        recipientId: event.recipientId,
        recipientType: event.recipientType,
      ),
    );

    result.fold(
      (failure) {
        _log('_onCreateConversation', 'Failed: ${failure.message}');
        emit(ConversationError(message: failure.message));
      },
      (conversation) {
        _log('_onCreateConversation', 'Success: ${conversation.id}');
        
        // Add to conversations list if not already present
        final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
        if (existingIndex == -1) {
          _conversations = [conversation, ..._conversations];
        }

        emit(ConversationCreated(conversation: conversation));
      },
    );
  }

  // ============== Message Handlers ==============

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onLoadMessages', 'Loading messages for ${event.conversationId}');

    if (event.refresh || !_messagesCache.containsKey(event.conversationId)) {
      emit(MessagesLoading(conversationId: event.conversationId));
    }

    final result = await getMessagesUseCase(
      GetMessagesParams(
        conversationId: event.conversationId,
        page: event.page,
        limit: 50,
      ),
    );

    result.fold(
      (failure) {
        _log('_onLoadMessages', 'Failed: ${failure.message}');
        emit(MessagesError(
          conversationId: event.conversationId,
          message: failure.message,
        ));
      },
      (messages) {
        _log('_onLoadMessages', 'Success: ${messages.length} messages');

        if (event.refresh || event.page == 1) {
          _messagesCache[event.conversationId] = messages;
        } else {
          _messagesCache[event.conversationId] = [
            ...(_messagesCache[event.conversationId] ?? []),
            ...messages,
          ];
        }

        // Find conversation for context
        final conversation = _conversations.firstWhere(
          (c) => c.id == event.conversationId,
          orElse: () => _createEmptyConversation(event.conversationId),
        );

        emit(MessagesLoaded(
          conversationId: event.conversationId,
          conversation: conversation,
          messages: _messagesCache[event.conversationId]!,
          hasMore: messages.length >= 50,
          currentPage: event.page,
        ));
      },
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onLoadMoreMessages', 'Loading more messages for ${event.conversationId}');

    final currentState = state;
    if (currentState is MessagesLoaded) {
      final result = await getMessagesUseCase(
        GetMessagesParams(
          conversationId: event.conversationId,
          page: currentState.currentPage + 1,
          limit: 50,
          before: event.beforeMessageId,
        ),
      );

      result.fold(
        (failure) {
          _log('_onLoadMoreMessages', 'Failed: ${failure.message}');
          // Don't emit error, just log
        },
        (messages) {
          _log('_onLoadMoreMessages', 'Success: ${messages.length} more messages');

          _messagesCache[event.conversationId] = [
            ...(_messagesCache[event.conversationId] ?? []),
            ...messages,
          ];

          emit(currentState.copyWith(
            messages: _messagesCache[event.conversationId],
            hasMore: messages.length >= 50,
            currentPage: currentState.currentPage + 1,
          ));
        },
      );
    }
  }

  Future<void> _onSendFileMessage(
    SendFileMessage event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onSendFileMessage', 'Sending file to ${event.conversationId}');

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    emit(MessageSending(conversationId: event.conversationId, tempId: tempId));

    final result = await sendFileMessageUseCase(
      SendFileMessageParams(
        conversationId: event.conversationId,
        file: event.file,
        caption: event.caption,
      ),
    );

    result.fold(
      (failure) {
        _log('_onSendFileMessage', 'Failed: ${failure.message}');
        emit(MessageSendError(
          conversationId: event.conversationId,
          message: failure.message,
          tempId: tempId,
        ));
      },
      (message) {
        _log('_onSendFileMessage', 'Success: ${message.id}');
        
        // Add message to cache
        if (_messagesCache.containsKey(event.conversationId)) {
          _messagesCache[event.conversationId] = [
            message,
            ...(_messagesCache[event.conversationId] ?? []),
          ];
        }

        emit(MessageSent(message: message, tempId: tempId));
        
        // Reload messages to show the new one
        add(LoadMessages(conversationId: event.conversationId, refresh: true));
      },
    );
  }

  Future<void> _onMarkMessagesRead(
    MarkMessagesRead event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onMarkMessagesRead', 'Marking messages as read for ${event.conversationId}');

    final result = await markMessagesReadUseCase(
      MarkMessagesReadParams(conversationId: event.conversationId),
    );

    result.fold(
      (failure) {
        _log('_onMarkMessagesRead', 'Failed: ${failure.message}');
      },
      (_) {
        _log('_onMarkMessagesRead', 'Success');
        
        // Update conversation unread count
        final index = _conversations.indexWhere((c) => c.id == event.conversationId);
        if (index != -1) {
          // Refresh conversations to get updated unread counts
          add(const LoadConversations(refresh: true));
        }

        // Refresh unread count
        add(const GetUnreadCount());
      },
    );
  }

  // ============== Unread Count Handlers ==============

  Future<void> _onGetUnreadCount(
    GetUnreadCount event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onGetUnreadCount', 'Getting unread count');

    final result = await getUnreadCountUseCase(NoParams());

    result.fold(
      (failure) {
        _log('_onGetUnreadCount', 'Failed: ${failure.message}');
      },
      (count) {
        _log('_onGetUnreadCount', 'Success: $count');
        _unreadCount = count;
        emit(UnreadCountLoaded(count: count));
      },
    );
  }

  void _onUpdateUnreadCount(
    UpdateUnreadCount event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onUpdateUnreadCount', 'Updating unread count to ${event.count}');
    _unreadCount = event.count;
    emit(UnreadCountLoaded(count: event.count));
  }

  // ============== Socket Event Handlers ==============

  void _onMessageReceived(
    MessageReceived event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onMessageReceived', 'Message received');

    try {
      final message = MessageModel.fromJson(event.messageData);
      
      // Add to cache if conversation is loaded
      if (_messagesCache.containsKey(message.conversationId)) {
        _messagesCache[message.conversationId] = [
          message.toEntity(),
          ...(_messagesCache[message.conversationId] ?? []),
        ];

        // Emit updated state if we're viewing this conversation
        final currentState = state;
        if (currentState is MessagesLoaded &&
            currentState.conversationId == message.conversationId) {
          emit(currentState.copyWith(
            messages: _messagesCache[message.conversationId],
          ));
        }
      }

      // Increment unread count
      _unreadCount++;
      
      // Refresh conversations to update last message
      add(const LoadConversations(refresh: true));
    } catch (e) {
      _log('_onMessageReceived', 'Error parsing message: $e');
    }
  }

  void _onTypingIndicatorReceived(
    TypingIndicatorReceived event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onTypingIndicatorReceived', 'User ${event.userId} is ${event.isTyping ? 'typing' : 'not typing'}');

    final currentState = state;
    if (currentState is MessagesLoaded &&
        currentState.conversationId == event.conversationId) {
      emit(currentState.copyWith(
        isTyping: event.isTyping,
        typingUserId: event.isTyping ? event.userId : null,
      ));
    }
  }

  // ============== Typing Event Handlers ==============

  void _onStartTyping(
    StartTyping event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onStartTyping', 'Start typing in ${event.conversationId}');
    messagingSocketService?.startTyping(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
    );
  }

  void _onStopTyping(
    StopTyping event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onStopTyping', 'Stop typing in ${event.conversationId}');
    messagingSocketService?.stopTyping(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
    );
  }

  // ============== Text Message Handler ==============

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onSendTextMessage', 'Sending text message to ${event.conversationId}');

    // Set current conversation context
    _currentConversationId = event.conversationId;
    _currentReceiverId = event.receiverId;

    // Stop typing indicator
    messagingSocketService?.stopTyping(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
    );

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    emit(MessageSending(conversationId: event.conversationId, tempId: tempId));

    // Send via socket for real-time delivery
    final success = messagingSocketService?.sendMessage(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
      content: event.content,
    ) ?? false;

    if (success) {
      _log('_onSendTextMessage', 'Message sent via socket');
      // The socket will emit new_message or message_sent event
      // which will trigger MessageReceived and update the UI
    } else {
      _log('_onSendTextMessage', 'Socket not connected, cannot send message');
      emit(MessageSendError(
        conversationId: event.conversationId,
        message: 'Not connected to messaging service',
        tempId: tempId,
      ));
    }
  }

  void _onUserOnline(
    UserOnline event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onUserOnline', 'User ${event.userId} is online');
    // Could update UI to show online status
  }

  void _onUserOffline(
    UserOffline event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onUserOffline', 'User ${event.userId} is offline');
    // Could update UI to show offline status
  }

  // ============== UI Handlers ==============

  void _onClearCurrentConversation(
    ClearCurrentConversation event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onClearCurrentConversation', 'Clearing current conversation');
    
    // Go back to conversations list
    if (_conversations.isNotEmpty) {
      emit(ConversationsLoaded(conversations: _conversations));
    } else {
      emit(const MessagingInitial());
    }
  }

  void _onResetMessaging(
    ResetMessaging event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onResetMessaging', 'Resetting messaging state');
    _conversations = [];
    _messagesCache = {};
    _unreadCount = 0;
    emit(const MessagingInitial());
  }

  // ============== Helper Methods ==============

  ConversationEntity _createEmptyConversation(String id) {
    return ConversationEntity(
      id: id,
      participantIds: [],
      conversationType: 'patient_doctor',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Join a conversation room for real-time updates
  void joinConversation(String conversationId) {
    _currentConversationId = conversationId;
    messagingSocketService?.joinConversation(conversationId);
  }

  /// Mark messages as read via socket (faster than REST)
  void markAsReadViaSocket(String conversationId, String senderId) {
    messagingSocketService?.markAsRead(
      conversationId: conversationId,
      senderId: senderId,
    );
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
