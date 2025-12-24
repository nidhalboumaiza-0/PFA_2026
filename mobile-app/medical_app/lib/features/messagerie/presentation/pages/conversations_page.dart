import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/constants.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_cubit.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_state.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/socket/socket_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/pages/chat_page.dart';

class ConversationsPage extends StatefulWidget {
  static const String routeName = '/conversations';

  const ConversationsPage({Key? key}) : super(key: key);

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMessaging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - force check socket connection
      debugPrint('App resumed - checking socket connection');
      context.read<SocketBloc>().add(const ConnectSocketEvent(forceReconnect: true));
      context.read<ConversationBloc>().add(FetchConversationsEvent());
    } else if (state == AppLifecycleState.paused) {
      // App went to background - socket stays connected for push notifications
      debugPrint('App paused - socket staying connected');
    }
  }

  void _initializeMessaging() {
    context.read<ConversationBloc>().add(FetchConversationsEvent());
    context.read<SocketBloc>().add(const ConnectSocketEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('messaging.messages')),
        actions: [
          // Show connection status indicator
          BlocBuilder<SocketBloc, SocketState>(
            builder: (context, socketState) {
              if (socketState is SocketReconnecting) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                );
              } else if (socketState is SocketError || socketState is SocketDisconnected) {
                return IconButton(
                  icon: const Icon(Icons.cloud_off, color: Colors.red),
                  onPressed: () {
                    context.read<SocketBloc>().add(ConnectSocketEvent());
                  },
                  tooltip: context.tr('messaging.reconnect'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ConversationBloc>().add(FetchConversationsEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${context.tr('common.error')}: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ConversationBloc>().add(
                        FetchConversationsEvent(),
                      );
                    },
                    child: Text(context.tr('common.try_again')),
                  ),
                ],
              ),
            );
          } else if (state is ConversationsLoaded) {
            final conversations = state.conversations;
            if (conversations.isEmpty) {
              return Center(child: Text(context.tr('messaging.no_conversations')));
            }
            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildConversationItem(context, conversations[index]);
              },
            );
          }

          return Center(child: Text(context.tr('messaging.start_conversation')));
        },
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    final currentUserId = context.read<ConversationBloc>().currentUserId;
    final otherName = conversation.displayName;
    final otherUserId = conversation.getOtherParticipantId(currentUserId) ?? '';

    final formattedDate = _formatDateTime(conversation.lastMessageTime ?? DateTime.now());

    // Determine if the message is unread
    final unreadCount = conversation.getUnreadCountForUser(currentUserId);
    final isUnread = unreadCount > 0;

    // Determine message preview
    String messagePreview = conversation.lastMessagePreview;
    if (messagePreview.isEmpty) {
      messagePreview = context.tr('messaging.no_messages_preview');
    }

    return BlocBuilder<OnlineStatusCubit, OnlineStatusState>(
      builder: (context, onlineState) {
        final isOnline = onlineState.isUserOnline(otherUserId);
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryColor,
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // Online indicator dot
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherName,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            messagePreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isUnread ? kPrimaryColor : Colors.grey,
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(conversation: conversation),
              ),
            ).then((_) {
              // Refresh conversations when returning from chat
              context.read<ConversationBloc>().add(FetchConversationsEvent());
            });
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today, show time
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week, show day name
      return DateFormat('EEEE').format(dateTime);
    } else {
      // Older, show date
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
