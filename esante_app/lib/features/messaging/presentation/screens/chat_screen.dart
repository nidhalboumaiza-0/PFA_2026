import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/messaging_bloc.dart';
import '../bloc/messaging_event.dart';
import '../bloc/messaging_state.dart';

/// Chat screen for a single conversation
class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<MessagingBloc>();
        // Join conversation room for real-time updates
        bloc.joinConversation(conversationId);
        // Load messages and mark as read
        bloc.add(LoadMessages(conversationId: conversationId));
        bloc.add(MarkMessagesRead(conversationId: conversationId));
        // Also mark via socket for faster delivery
        bloc.markAsReadViaSocket(conversationId, recipientId);
        return bloc;
      },
      child: _ChatView(
        conversationId: conversationId,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientAvatarUrl: recipientAvatarUrl,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;

  const _ChatView({
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _isComposing = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Stop typing indicator when leaving
    if (_isTyping) {
      _stopTyping();
    }
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isComposing) {
      setState(() {
        _isComposing = hasText;
      });
    }

    // Handle typing indicator
    if (hasText) {
      if (!_isTyping) {
        _startTyping();
      }
      // Reset the timer on each keystroke
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _stopTyping();
      });
    } else {
      _stopTyping();
    }
  }

  void _startTyping() {
    if (_isTyping) return;
    _isTyping = true;
    context.read<MessagingBloc>().add(StartTyping(
      conversationId: widget.conversationId,
      receiverId: widget.recipientId,
    ));
  }

  void _stopTyping() {
    if (!_isTyping) return;
    _isTyping = false;
    _typingTimer?.cancel();
    context.read<MessagingBloc>().add(StopTyping(
      conversationId: widget.conversationId,
      receiverId: widget.recipientId,
    ));
  }

  void _onScroll() {
    // Load more messages when scrolling to top
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<MessagingBloc>().state;
      if (state is MessagesLoaded && state.hasMore) {
        final oldestMessage = state.messages.isNotEmpty
            ? state.messages.last.id
            : null;
        context.read<MessagingBloc>().add(LoadMoreMessages(
              conversationId: widget.conversationId,
              beforeMessageId: oldestMessage,
            ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              backgroundImage: widget.recipientAvatarUrl != null
                  ? NetworkImage(widget.recipientAvatarUrl!)
                  : null,
              child: widget.recipientAvatarUrl == null
                  ? Text(
                      _getInitials(widget.recipientName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBodyText(
                    text: widget.recipientName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  BlocBuilder<MessagingBloc, MessagingState>(
                    builder: (context, state) {
                      if (state is MessagesLoaded && state.isTyping) {
                        return AppSmallText(
                          text: 'typing...',
                          color: AppColors.success,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              builder: (context, state) {
                if (state is MessagesLoading) {
                  return const _MessagesLoadingView();
                }

                if (state is MessagesError) {
                  return _MessagesErrorView(
                    message: state.message,
                    onRetry: () {
                      context.read<MessagingBloc>().add(
                            LoadMessages(conversationId: widget.conversationId),
                          );
                    },
                  );
                }

                if (state is MessagesLoaded) {
                  if (state.messages.isEmpty) {
                    return const _EmptyMessagesView();
                  }

                  return _MessagesList(
                    messages: state.messages,
                    scrollController: _scrollController,
                    currentUserId: HiveStorageService.getCurrentUserId() ?? '',
                  );
                }

                return const _MessagesLoadingView();
              },
            ),
          ),

          // Message input
          _MessageInputBar(
            controller: _messageController,
            isComposing: _isComposing,
            onSend: _sendMessage,
            onAttachment: _showAttachmentOptions,
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Stop typing indicator
    _stopTyping();

    // Send via socket for real-time delivery
    context.read<MessagingBloc>().add(SendTextMessage(
      conversationId: widget.conversationId,
      receiverId: widget.recipientId,
      content: text,
    ));

    _messageController.clear();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.photo, color: Colors.white),
              ),
              title: const AppBodyText(text: 'Photo'),
              subtitle: const AppSmallText(text: 'Share an image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const AppBodyText(text: 'Camera'),
              subtitle: const AppSmallText(text: 'Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.warning,
                child: Icon(Icons.attach_file, color: Colors.white),
              ),
              title: const AppBodyText(text: 'Document'),
              subtitle: const AppSmallText(text: 'Share a file'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        _sendFileMessage(File(pickedFile.path));
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to pick image');
    }
  }

  Future<void> _pickDocument() async {
    // TODO: Implement document picker
    AppSnackbar.showInfo(context, 'Document picker not implemented yet');
  }

  void _sendFileMessage(File file) {
    context.read<MessagingBloc>().add(SendFileMessage(
          conversationId: widget.conversationId,
          file: file,
        ));
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const AppBodyText(text: 'View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const AppBodyText(text: 'Search in Conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const AppBodyText(text: 'Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mute
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading view for messages
class _MessagesLoadingView extends StatelessWidget {
  const _MessagesLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.all(16.w),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ShimmerLoading(
              child: Container(
                height: 48.h,
                width: 200.w + (index % 3) * 40.0.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Error view for messages
class _MessagesErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessagesErrorView({
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
              size: 48.sp,
              color: AppColors.error.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            AppBodyText(message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
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

/// Empty messages view
class _EmptyMessagesView extends StatelessWidget {
  const _EmptyMessagesView();

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
              size: 64.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            AppBodyText(
              'No messages yet',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            AppSmallText(
              'Send a message to start the conversation',
              textAlign: TextAlign.center,
              color: AppColors.textSecondaryStatic,
            ),
          ],
        ),
      ),
    );
  }
}

/// Messages list widget
class _MessagesList extends StatelessWidget {
  final List<MessageEntity> messages;
  final ScrollController scrollController;
  final String currentUserId;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.isMine(currentUserId);
        final showAvatar = !isMe &&
            (index == messages.length - 1 ||
                messages[index + 1].senderId != message.senderId);

        return _MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
        );
      },
    );
  }
}

/// Single message bubble
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              child: Text(
                message.sender?.name.isNotEmpty == true
                    ? message.sender!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ] else if (!isMe) ...[
            SizedBox(width: 40.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : theme.brightness == Brightness.dark
                        ? AppColors.grey600
                        : AppColors.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content based on message type
                  if (message.messageType == MessageType.image &&
                      message.attachment != null)
                    _buildImageContent()
                  else if (message.messageType == MessageType.document &&
                      message.attachment != null)
                    _buildDocumentContent()
                  else
                    AppBodyText(
                      text: message.content ?? '',
                      color: isMe ? Colors.white : null,
                      fontSize: 15.sp,
                    ),

                  SizedBox(height: 4.h),

                  // Time and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSmallText(
                        text: message.timeString,
                        fontSize: 11.sp,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textSecondaryStatic,
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14.sp,
                          color: message.isRead
                              ? Colors.lightBlueAccent
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            message.attachment!.s3Url ?? '',
            width: 200.w,
            height: 150.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200.w,
              height: 150.h,
              color: AppColors.grey200,
              child: Icon(Icons.broken_image, size: 48.sp),
            ),
          ),
        ),
        if (message.content?.isNotEmpty == true) ...[
          SizedBox(height: 8.h),
          AppBodyText(
            text: message.content!,
            color: isMe ? Colors.white : null,
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white : AppColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBodyText(
                text: message.attachment!.fileName,
                color: isMe ? Colors.white : null,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSmallText(
                text: message.attachment!.formattedSize,
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textSecondaryStatic,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Message input bar
class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isComposing;
  final VoidCallback onSend;
  final VoidCallback onAttachment;

  const _MessageInputBar({
    required this.controller,
    required this.isComposing,
    required this.onSend,
    required this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8.w,
        right: 8.w,
        top: 8.h,
        bottom: MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 4.r,
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: onAttachment,
            color: AppColors.textSecondaryStatic,
          ),

          // Text field using CustomTextField
          Expanded(
            child: CustomTextField(
              controller: controller,
              hintText: 'Type a message...',
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => onSend(),
            ),
          ),

          SizedBox(width: 8.w),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: CircleAvatar(
              backgroundColor: isComposing ? AppColors.primary : AppColors.grey300,
              child: IconButton(
                icon: Icon(Icons.send, size: 20.sp),
                color: Colors.white,
                onPressed: isComposing ? onSend : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
