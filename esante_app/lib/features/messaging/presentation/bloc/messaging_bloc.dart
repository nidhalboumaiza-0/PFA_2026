import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/messaging_socket_service.dart';
import '../../../../core/storage/hive_storage_service.dart';
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
  String? _cachedUserId;

  // Socket subscription
  StreamSubscription<MessagingSocketEvent>? _socketSubscription;

  // Current conversation context for typing
  String? _currentConversationId;

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
    on<MessageSentConfirmation>(_onMessageSentConfirmation);

    // Subscribe to socket events
    _subscribeToSocket();
  }

  void _log(String method, String message) {
    print('[MessagingBloc.$method] $message');
  }

  /// Subscribe to socket events
  void _subscribeToSocket() {
    if (messagingSocketService == null) {
      _log('_subscribeToSocket', '❌ messagingSocketService is NULL!');
      return;
    }

    _log('_subscribeToSocket', '✅ Subscribing to socket events...');
    _socketSubscription = messagingSocketService!.eventStream.listen((event) {
      _log('_subscribeToSocket', '📨 Received socket event: ${event.type}');
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
        case MessagingSocketEventType.messageSent:
          // Handle message sent confirmation
          if (event.data != null) {
            _log('_subscribeToSocket', 'Message sent confirmed: ${event.data}');
            add(MessageSentConfirmation(
              tempId: event.data!['tempId'] ?? '',
              messageData: event.data!,
            ));
          }
          break;
        case MessagingSocketEventType.messageDelivered:
          // Message was delivered to recipient, could update UI
          if (event.data != null) {
            _log('_subscribeToSocket', 'Message delivered: ${event.data}');
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

  /// Helper to update a conversation's lastMessage in the cache
  void _updateConversationLastMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required DateTime timestamp,
    bool incrementUnread = false,
  }) {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    _log('_updateConversationLastMessage', 'Looking for conversation $conversationId, found at index: $convIndex');
    
    if (convIndex != -1) {
      final oldConv = _conversations[convIndex];
      final newUnreadCount = incrementUnread ? oldConv.unreadCount + 1 : oldConv.unreadCount;
      _log('_updateConversationLastMessage', 'Old unreadCount: ${oldConv.unreadCount}, incrementUnread: $incrementUnread, new unreadCount: $newUnreadCount');
      
      final updatedConv = oldConv.copyWith(
        unreadCount: newUnreadCount,
        lastMessage: LastMessageEntity(
          content: content,
          senderId: senderId,
          timestamp: timestamp,
          isRead: !incrementUnread,
        ),
        updatedAt: timestamp,
      );
      
      _log('_updateConversationLastMessage', 'Updated conversation unreadCount: ${updatedConv.unreadCount}, hasUnread: ${updatedConv.hasUnread}');
      
      // Remove old and insert updated at correct position
      _conversations.removeAt(convIndex);
      _conversations.insert(0, updatedConv); // Always move to top
      
      _log('_updateConversationLastMessage', 'Moved conversation to top. First conversation unreadCount: ${_conversations[0].unreadCount}');
    } else {
      _log('_updateConversationLastMessage', 'Conversation not found in cache!');
    }
  }

  // ============== Conversation Handlers ==============

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onLoadConversations', 'Loading conversations (page: ${event.page}, refresh: ${event.refresh}, forceEmit: ${event.forceEmit})');

    // Only show loading if we have NO cached conversations
    // This prevents flicker when refreshing with existing data
    final currentState = state;
    if (_conversations.isEmpty && (currentState is! MessagesLoaded || event.forceEmit)) {
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
        // Don't emit error if we're in MessagesLoaded state (unless forceEmit)
        final currentState = state;
        if (currentState is! MessagesLoaded || event.forceEmit) {
          emit(ConversationsError(message: failure.message));
        }
      },
      (conversations) {
        _log('_onLoadConversations', 'Success: ${conversations.length} conversations');

        if (event.refresh || event.page == 1) {
          _conversations = conversations;
        } else {
          _conversations = [..._conversations, ...conversations];
        }

        // Don't emit ConversationsLoaded if we're in MessagesLoaded state
        // This preserves the chat state for typing/message updates
        // Unless forceEmit is true (conversations screen needs update)
        final currentState = state;
        if (currentState is MessagesLoaded && !event.forceEmit) {
          _log('_onLoadConversations', 'Preserving MessagesLoaded state, not emitting ConversationsLoaded');
          // Just update the cached conversations, don't change state
        } else {
          emit(ConversationsLoaded(
            conversations: _conversations,
            hasMore: conversations.length >= 20,
            currentPage: event.page,
          ));
        }
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

        // Sort messages newest-first (descending by createdAt) for reverse ListView
        final sortedMessages = List<MessageEntity>.from(messages)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (event.refresh || event.page == 1) {
          _messagesCache[event.conversationId] = sortedMessages;
        } else {
          // For pagination, add older messages at the end
          final allMessages = <MessageEntity>[
            ...(_messagesCache[event.conversationId] ?? []),
            ...sortedMessages,
          ];
          // Re-sort to ensure correct order
          allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _messagesCache[event.conversationId] = allMessages;
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

          // Combine and sort all messages newest-first
          final allMessages = <MessageEntity>[
            ...(_messagesCache[event.conversationId] ?? []),
            ...messages,
          ];
          allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _messagesCache[event.conversationId] = allMessages;

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
    final currentUserId = await _getCurrentUserId();
    
    // Determine message type based on file extension
    final extension = event.file.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final messageType = isImage ? MessageType.image : MessageType.document;
    
    // Create optimistic message with local file path
    final optimisticMessage = MessageEntity(
      id: 'temp_$tempId',
      conversationId: event.conversationId,
      senderId: currentUserId,
      senderType: 'user',
      receiverId: event.receiverId,
      receiverType: 'user',
      messageType: messageType,
      content: event.file.path, // Use local file path for preview
      isDelivered: false,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {'uploading': true, 'tempId': tempId}, // Mark as uploading
    );

    // Add optimistic message to state and cache
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final updatedMessages = [optimisticMessage, ...currentState.messages];
      _messagesCache[event.conversationId] = updatedMessages;
      emit(currentState.copyWith(messages: updatedMessages));
    } else {
      _messagesCache[event.conversationId] = [
        optimisticMessage,
        ...(_messagesCache[event.conversationId] ?? []),
      ];
    }

    final result = await sendFileMessageUseCase(
      SendFileMessageParams(
        conversationId: event.conversationId,
        receiverId: event.receiverId,
        file: event.file,
        caption: event.caption,
      ),
    );

    result.fold(
      (failure) {
        _log('_onSendFileMessage', 'Failed: ${failure.message}');
        // Remove optimistic message on failure
        final currentState = state;
        if (currentState is MessagesLoaded) {
          final messagesWithoutOptimistic = currentState.messages
              .where((m) => m.id != 'temp_$tempId')
              .toList();
          _messagesCache[event.conversationId] = messagesWithoutOptimistic;
          emit(currentState.copyWith(messages: messagesWithoutOptimistic));
        }
        emit(MessageSendError(
          conversationId: event.conversationId,
          message: failure.message,
          tempId: tempId,
        ));
      },
      (message) {
        _log('_onSendFileMessage', 'Success: ${message.id}');
        
        // Replace optimistic message with real message
        final currentState = state;
        if (currentState is MessagesLoaded) {
          final updatedMessages = currentState.messages.map((m) {
            if (m.id == 'temp_$tempId') {
              return message; // Replace with real message from server
            }
            return m;
          }).toList();
          _messagesCache[event.conversationId] = updatedMessages;
          emit(currentState.copyWith(messages: updatedMessages));
        }
        
        // Refresh conversations to update last message preview
        add(const LoadConversations(refresh: true));
      },
    );
  }

  Future<void> _onMarkMessagesRead(
    MarkMessagesRead event,
    Emitter<MessagingState> emit,
  ) async {
    _log('_onMarkMessagesRead', 'Marking messages as read for ${event.conversationId}');

    // Immediately update local cache for responsive UI
    final index = _conversations.indexWhere((c) => c.id == event.conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      _log('_onMarkMessagesRead', 'Immediately updated local cache for conversation');
    }

    final result = await markMessagesReadUseCase(
      MarkMessagesReadParams(conversationId: event.conversationId),
    );

    result.fold(
      (failure) {
        _log('_onMarkMessagesRead', 'Failed: ${failure.message}');
      },
      (_) {
        _log('_onMarkMessagesRead', 'Success');

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
        // Don't emit UnreadCountLoaded if we're in MessagesLoaded state
        // This preserves the chat state and allows typing/message updates
        final currentState = state;
        if (currentState is MessagesLoaded) {
          _log('_onGetUnreadCount', 'Preserving MessagesLoaded state');
          // Keep the current state, just update the cached count
        } else {
          emit(UnreadCountLoaded(count: count));
        }
      },
    );
  }

  void _onUpdateUnreadCount(
    UpdateUnreadCount event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onUpdateUnreadCount', 'Updating unread count to ${event.count}');
    _unreadCount = event.count;
    // Don't emit if we're in MessagesLoaded state to preserve chat state
    final currentState = state;
    if (currentState is! MessagesLoaded) {
      emit(UnreadCountLoaded(count: event.count));
    }
  }

  // ============== Socket Event Handlers ==============

  void _onMessageReceived(
    MessageReceived event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onMessageReceived', '📥 Message received: ${event.messageData}');

    try {
      final message = MessageModel.fromJson(event.messageData);
      _log('_onMessageReceived', '📥 Parsed message for conversation: ${message.conversationId}');
      
      // Update cache - create if doesn't exist
      if (!_messagesCache.containsKey(message.conversationId)) {
        _messagesCache[message.conversationId] = [];
      }
      
      // Check if message already exists (avoid duplicates)
      final existingIndex = _messagesCache[message.conversationId]!
          .indexWhere((m) => m.id == message.id);
      if (existingIndex == -1) {
        // Add new message at the beginning (newest first)
        _messagesCache[message.conversationId] = [
          message.toEntity(),
          ...(_messagesCache[message.conversationId] ?? []),
        ];
        _log('_onMessageReceived', '📥 Added message to cache');
      } else {
        _log('_onMessageReceived', '📥 Message already exists in cache, skipping');
        return; // Don't process duplicate
      }

      // Check if we're currently viewing this conversation
      final currentState = state;
      final isViewingThisConversation = currentState is MessagesLoaded &&
          currentState.conversationId == message.conversationId;
      
      _log('_onMessageReceived', '📥 Current state: ${currentState.runtimeType}, isViewingThisConversation: $isViewingThisConversation');

      // Always update the conversation's lastMessage in cache
      _updateConversationLastMessage(
        conversationId: message.conversationId,
        content: message.content ?? 'File attachment',
        senderId: message.senderId,
        timestamp: message.createdAt,
        incrementUnread: !isViewingThisConversation, // Only increment unread if not viewing
      );
      
      if (isViewingThisConversation) {
        // We're viewing this conversation - update the messages
        _log('_onMessageReceived', '📥 Emitting updated state with ${_messagesCache[message.conversationId]!.length} messages');
        emit(currentState.copyWith(
          messages: _messagesCache[message.conversationId],
        ));
      } else {
        // Not viewing this conversation - increment global unread count
        _log('_onMessageReceived', '📥 Not in this conversation, incrementing unread count');
        _unreadCount++;
        
        // If we're on conversations screen, emit updated list to show new message indicator
        if (currentState is ConversationsLoaded) {
          // Verify the first conversation has the updated unread count
          if (_conversations.isNotEmpty) {
            _log('_onMessageReceived', '📥 First conversation: ${_conversations[0].displayName}, unreadCount: ${_conversations[0].unreadCount}, lastMessage: ${_conversations[0].lastMessage?.content}');
          }
          _log('_onMessageReceived', '📥 Emitting updated ConversationsLoaded with ${_conversations.length} conversations');
          emit(ConversationsLoaded(
            conversations: List<ConversationEntity>.from(_conversations),
            hasMore: currentState.hasMore,
            currentPage: currentState.currentPage,
            lastUpdated: DateTime.now(), // Force state change
          ));
        }
      }
    } catch (e, stack) {
      _log('_onMessageReceived', '❌ Error parsing message: $e');
      _log('_onMessageReceived', '❌ Stack: $stack');
    }
  }

  void _onTypingIndicatorReceived(
    TypingIndicatorReceived event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onTypingIndicatorReceived', 'User ${event.userId} is ${event.isTyping ? 'typing' : 'not typing'} in conversation ${event.conversationId}');
    _log('_onTypingIndicatorReceived', 'Current state: ${state.runtimeType}, _currentConversationId: $_currentConversationId');

    final currentState = state;
    if (currentState is MessagesLoaded) {
      _log('_onTypingIndicatorReceived', 'State conversationId: ${currentState.conversationId}, Event conversationId: ${event.conversationId}');
      if (currentState.conversationId == event.conversationId) {
        _log('_onTypingIndicatorReceived', 'Emitting typing state: ${event.isTyping}');
        emit(currentState.copyWith(
          isTyping: event.isTyping,
          typingUserId: event.isTyping ? event.userId : null,
        ));
      } else {
        _log('_onTypingIndicatorReceived', 'ConversationId mismatch - not updating');
      }
    } else {
      _log('_onTypingIndicatorReceived', 'State is not MessagesLoaded - cannot update typing');
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

    // Stop typing indicator
    messagingSocketService?.stopTyping(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
    );

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final currentUserId = await _getCurrentUserId();
    
    // Create optimistic message to show immediately
    final optimisticMessage = MessageEntity(
      id: 'temp_$tempId',
      conversationId: event.conversationId,
      senderId: currentUserId,
      senderType: 'user',
      receiverId: event.receiverId,
      receiverType: 'user',
      messageType: MessageType.text,
      content: event.content,
      isDelivered: false,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add optimistic message to the current state AND cache (at the beginning since list is reversed)
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final updatedMessages = [optimisticMessage, ...currentState.messages];
      // Also update the cache to keep it in sync
      _messagesCache[event.conversationId] = updatedMessages;
      emit(currentState.copyWith(messages: updatedMessages));
    } else {
      // If not in MessagesLoaded state, still update cache
      _messagesCache[event.conversationId] = [
        optimisticMessage,
        ...(_messagesCache[event.conversationId] ?? []),
      ];
    }
    
    // Update the conversation's lastMessage immediately for responsive UI
    _updateConversationLastMessage(
      conversationId: event.conversationId,
      content: event.content,
      senderId: currentUserId,
      timestamp: DateTime.now(),
      incrementUnread: false,
    );

    // Check if socket is connected
    if (messagingSocketService?.isConnected != true) {
      _log('_onSendTextMessage', 'Socket not connected, cannot send message');
      // Remove optimistic message on error from both state and cache
      if (currentState is MessagesLoaded) {
        final messagesWithoutOptimistic = currentState.messages
            .where((m) => m.id != 'temp_$tempId')
            .toList();
        _messagesCache[event.conversationId] = messagesWithoutOptimistic;
        emit(currentState.copyWith(messages: messagesWithoutOptimistic));
      }
      emit(MessageSendError(
        conversationId: event.conversationId,
        message: 'Not connected to messaging service',
        tempId: tempId,
      ));
      return;
    }

    // Send via socket for real-time delivery
    messagingSocketService!.sendMessage(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
      content: event.content,
      tempId: tempId,
    );
    
    _log('_onSendTextMessage', 'Message sent via socket');
    // The socket will emit message_sent event which will replace the optimistic message
  }
  
  Future<String> _getCurrentUserId() async {
    // Check cache first
    if (_cachedUserId != null) return _cachedUserId!;
    
    // Get from HiveStorageService
    _cachedUserId = HiveStorageService.getCurrentUserId();
    return _cachedUserId ?? '';
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

  // ============== Message Sent Confirmation Handler ==============

  void _onMessageSentConfirmation(
    MessageSentConfirmation event,
    Emitter<MessagingState> emit,
  ) {
    _log('_onMessageSentConfirmation', 'Message sent confirmed with tempId: ${event.tempId}');
    _log('_onMessageSentConfirmation', 'Server data: ${event.messageData}');
    
    // Parse attachment from server response if present
    AttachmentEntity? parsedAttachment;
    if (event.messageData['attachment'] != null) {
      final attachmentData = event.messageData['attachment'];
      parsedAttachment = AttachmentEntity(
        fileName: attachmentData['fileName'] ?? 'file',
        fileSize: attachmentData['fileSize'] ?? 0,
        mimeType: attachmentData['mimeType'] ?? 'application/octet-stream',
        s3Key: attachmentData['s3Key'],
        s3Url: attachmentData['s3Url'] ?? attachmentData['url'],
      );
      _log('_onMessageSentConfirmation', 'Parsed attachment: ${parsedAttachment.s3Url}');
    }
    
    // Update the optimistic message with the real message from server
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == 'temp_${event.tempId}') {
          // Replace with real message data including attachment
          return MessageEntity(
            id: event.messageData['id'] ?? event.messageData['_id'] ?? msg.id,
            conversationId: msg.conversationId,
            senderId: msg.senderId,
            senderType: msg.senderType,
            receiverId: msg.receiverId,
            receiverType: msg.receiverType,
            messageType: msg.messageType,
            content: event.messageData['content'] ?? msg.content,
            attachment: parsedAttachment, // Include the attachment from server
            isDelivered: true,
            isRead: false,
            createdAt: msg.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return msg;
      }).toList();
      
      // Also update the cache to keep it in sync
      _messagesCache[currentState.conversationId] = updatedMessages;
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
    
    // Refresh conversations to update last message preview
    add(const LoadConversations(refresh: true));
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
  void markAsReadViaSocket(String conversationId, {List<String>? messageIds}) {
    messagingSocketService?.markAsRead(
      conversationId: conversationId,
      messageIds: messageIds,
    );
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
