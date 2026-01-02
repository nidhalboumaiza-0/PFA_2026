import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/conversation_entity.dart';
import '../bloc/messaging_bloc.dart';
import '../bloc/messaging_event.dart';
import '../bloc/messaging_state.dart';
import 'chat_screen.dart';

/// Screen showing list of conversations
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagingBloc>()..add(const LoadConversations()),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Messages',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<MessagingBloc>().add(const LoadConversations(refresh: true));
        },
        child: BlocBuilder<MessagingBloc, MessagingState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const _LoadingView();
            }

            if (state is ConversationsError) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<MessagingBloc>().add(const LoadConversations());
                },
              );
            }

            if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return const _EmptyView();
              }

              return _ConversationsList(
                conversations: state.conversations,
              );
            }

            // Initial state
            return const _LoadingView();
          },
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SearchMessagesDialog(),
    );
  }
}

/// Loading shimmer view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 8,
      itemBuilder: (context, index) => const _ConversationShimmer(),
    );
  }
}

/// Shimmer placeholder for conversation item
class _ConversationShimmer extends StatelessWidget {
  const _ConversationShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ShimmerLoading(
        child: Row(
          children: [
            CircleAvatar(radius: 28.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.h,
                    width: 120.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view with retry button
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.error.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            AppBodyText(
              message,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Retry',
              onPressed: onRetry,
              type: ButtonType.outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no conversations
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 24.h),
            AppTitle(
              text: 'No conversations yet',
              fontSize: 20.sp,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            AppBodyText(
              'Start a conversation with your doctor or patients',
              textAlign: TextAlign.center,
              color: AppColors.textSecondaryStatic,
            ),
          ],
        ),
      ),
    );
  }
}

/// List of conversations
class _ConversationsList extends StatelessWidget {
  final List<ConversationEntity> conversations;

  const _ConversationsList({
    required this.conversations,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 76.w),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(
          conversation: conversation,
          onTap: () => _openChat(context, conversation),
        );
      },
    );
  }

  void _openChat(BuildContext context, ConversationEntity conversation) {
    // Get recipient ID from other participant or first participant that's not current user
    final recipientId = conversation.otherParticipant?.id ?? 
                        (conversation.participantIds.isNotEmpty 
                            ? conversation.participantIds.first 
                            : '');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          recipientId: recipientId,
          recipientName: conversation.displayName,
          recipientAvatarUrl: conversation.avatarUrl,
        ),
      ),
    );
  }
}

/// Single conversation tile
class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.hasUnread;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            backgroundImage: conversation.avatarUrl != null
                ? NetworkImage(conversation.avatarUrl!)
                : null,
            child: conversation.avatarUrl == null
                ? Text(
                    _getInitials(conversation.displayName),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          if (conversation.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.w,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: AppBodyText(
              conversation.displayName,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
              fontSize: 16.sp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessage != null)
            AppSmallText(
              text: _formatTime(conversation.lastMessage!.timestamp),
              fontSize: 12.sp,
              color: hasUnread
                  ? AppColors.primary
                  : AppColors.textSecondaryStatic,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: AppSmallText(
              text: conversation.lastMessage?.content ?? 'No messages yet',
              color: hasUnread
                  ? AppColors.textPrimaryStatic
                  : AppColors.textSecondaryStatic,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppSmallText(
                text: conversation.unreadCount.toString(),
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      // Today - show time
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      // Older - show date
      return '${time.day}/${time.month}';
    }
  }
}

/// Search messages dialog
class _SearchMessagesDialog extends StatefulWidget {
  const _SearchMessagesDialog();

  @override
  State<_SearchMessagesDialog> createState() => _SearchMessagesDialogState();
}

class _SearchMessagesDialogState extends State<_SearchMessagesDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppTitle(text: 'Search Messages', fontSize: 18.sp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _searchController,
            hintText: 'Search for messages...',
            prefixIcon: Icons.search,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: AppBodyText('Cancel', color: AppColors.textSecondaryStatic),
        ),
        CustomButton(
          text: 'Search',
          onPressed: () {
            // TODO: Implement search
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
