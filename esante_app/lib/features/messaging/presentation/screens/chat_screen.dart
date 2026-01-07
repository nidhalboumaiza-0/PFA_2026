import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../doctors/presentation/screens/doctor_detail_screen.dart';
import '../../../profile/presentation/screens/patient_detail_screen.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/messaging_bloc.dart';
import '../bloc/messaging_event.dart';
import '../bloc/messaging_state.dart';
import '../widgets/full_screen_image_viewer.dart';

/// Chat screen for a single conversation
class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;
  final String recipientType; // 'doctor' or 'patient'

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
    this.recipientType = 'doctor',
  });

  @override
  Widget build(BuildContext context) {
    // Use the global MessagingBloc from the app-level provider
    final bloc = context.read<MessagingBloc>();
    
    // Join conversation room for real-time updates
    bloc.joinConversation(conversationId);
    // Load messages and mark as read
    bloc.add(LoadMessages(conversationId: conversationId));
    bloc.add(MarkMessagesRead(conversationId: conversationId));
    // Also mark via socket for faster delivery
    bloc.markAsReadViaSocket(conversationId);
    
    return _ChatView(
      conversationId: conversationId,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientAvatarUrl: recipientAvatarUrl,
      recipientType: recipientType,
    );
  }
}

class _ChatView extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;
  final String recipientType;

  const _ChatView({
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
    this.recipientType = 'doctor',
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isComposing = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSearching = false;
  String _searchQuery = '';

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
    _searchController.dispose();
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

  PreferredSizeWidget _buildNormalAppBar() {
    return CustomAppBar(
      titleWidget: Row(
        children: [
          SizedBox(width: 8.w), // Spacing after back arrow
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
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
        onPressed: _stopSearch,
      ),
      title: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            Icon(
              Icons.search,
              color: AppColors.textSecondary(context),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in conversation...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(context).withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary(context),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textSecondary(context),
                    size: 18.sp,
                  ),
                ),
              )
            else
              SizedBox(width: 12.w),
          ],
        ),
      ),
      titleSpacing: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              buildWhen: (previous, current) {
                // Only rebuild for message-related states
                return current is MessagesLoading ||
                    current is MessagesLoaded ||
                    current is MessagesError ||
                    current is MessageSent ||
                    current is MessageSending ||
                    current is MessageSendError;
              },
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
                  final messages = _isSearching 
                      ? _filterMessages(state.messages) 
                      : state.messages;
                  
                  if (messages.isEmpty) {
                    if (_isSearching && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            AppBodyText(
                              text: 'No messages found for "$_searchQuery"',
                              color: AppColors.textSecondary(context),
                            ),
                          ],
                        ),
                      );
                    }
                    return const _EmptyMessagesView();
                  }

                  return _MessagesList(
                    messages: messages,
                    scrollController: _scrollController,
                    currentUserId: HiveStorageService.getCurrentUserId() ?? '',
                    highlightQuery: _isSearching ? _searchQuery : null,
                    recipientName: widget.recipientName,
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
      AppSnackBar.error(context, 'Failed to pick image');
    }
  }

  Future<void> _pickDocument() async {
    // TODO: Implement document picker
    AppSnackBar.info(context, 'Document picker not implemented yet');
  }

  void _sendFileMessage(File file) {
    context.read<MessagingBloc>().add(SendFileMessage(
          conversationId: widget.conversationId,
          receiverId: widget.recipientId,
          file: file,
        ));
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              
              // Header with recipient info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: widget.recipientAvatarUrl != null
                          ? NetworkImage(widget.recipientAvatarUrl!)
                          : null,
                      child: widget.recipientAvatarUrl == null
                          ? Text(
                              widget.recipientName.isNotEmpty
                                  ? widget.recipientName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                          SizedBox(height: 2.h),
                          AppSmallText(
                            text: widget.recipientType == 'doctor' ? 'Doctor' : 'Patient',
                            color: AppColors.textSecondary(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey[300]),
              
              // Options
              _buildOptionTile(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: 'View Profile',
                subtitle: 'See full profile details',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToProfile();
                },
              ),
              _buildOptionTile(
                icon: Icons.search,
                iconColor: Colors.orange,
                title: 'Search in Conversation',
                subtitle: 'Find messages in this chat',
                onTap: () {
                  Navigator.pop(context);
                  _startSearch();
                },
              ),
              
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBodyText(
                    text: title,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                  SizedBox(height: 2.h),
                  AppSmallText(
                    text: subtitle,
                    color: AppColors.textSecondary(context),
                    fontSize: 12.sp,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22.sp),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    if (widget.recipientType == 'doctor') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DoctorDetailScreen(doctorId: widget.recipientId),
        ),
      );
    } else {
      // Navigate to patient detail screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patientId: widget.recipientId),
        ),
      );
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<MessageEntity> _filterMessages(List<MessageEntity> messages) {
    if (_searchQuery.isEmpty) return messages;
    return messages.where((m) => 
      m.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
    ).toList();
  }
}

/// Loading view for messages
class _MessagesLoadingView extends StatelessWidget {
  const _MessagesLoadingView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    
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
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
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
            AppBodyText(text: message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Retry',
              onPressed: onRetry,
              isOutlined: true,
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
              text: 'No messages yet',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            AppSmallText(
              text: 'Send a message to start the conversation',
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
  final String? highlightQuery;
  final String recipientName;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
    this.highlightQuery,
    required this.recipientName,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Log currentUserId
    print('[_MessagesList] currentUserId: $currentUserId');
    if (messages.isNotEmpty) {
      print('[_MessagesList] First message senderId: ${messages.first.senderId}');
    }
    
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.isMine(currentUserId);
        
        // Debug first few messages
        if (index < 3) {
          print('[_MessagesList] Message[$index] senderId: ${message.senderId}, currentUserId: $currentUserId, isMe: $isMe');
        }
        
        final showAvatar = !isMe &&
            (index == messages.length - 1 ||
                messages[index + 1].senderId != message.senderId);

        return _MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          highlightQuery: highlightQuery,
          fallbackName: recipientName,
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
  final String? highlightQuery;
  final String? fallbackName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.highlightQuery,
    this.fallbackName,
  });

  /// Get initials from sender name (up to 2 letters)
  String _getSenderInitials(String? name) {
    final displayName = (name != null && name.isNotEmpty) ? name : fallbackName;
    if (displayName == null || displayName.isEmpty) return '?';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

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
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getSenderInitials(message.sender?.name),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
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
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF0084FF) // Messenger blue for sent
                    : theme.brightness == Brightness.dark
                        ? const Color(0xFF3E4042) // Dark grey for received in dark mode
                        : const Color(0xFFE4E6EB), // Light grey for received in light mode
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 18.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content based on message type
                  if (message.messageType == MessageType.image)
                    _buildImageContent(context)
                  else if (message.messageType == MessageType.document)
                    _buildDocumentContent(context)
                  else
                    _buildTextContent(context, theme),

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
                        if (message.isUploading)
                          SizedBox(
                            width: 14.sp,
                            height: 14.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          )
                        else
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

  Widget _buildTextContent(BuildContext context, ThemeData theme) {
    final content = message.content ?? '';
    final textColor = isMe 
        ? Colors.white 
        : theme.brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black87;
    
    // If no highlight query, just show plain text
    if (highlightQuery == null || highlightQuery!.isEmpty) {
      return Text(
        content,
        style: TextStyle(
          color: textColor,
          fontSize: 15.sp,
        ),
      );
    }
    
    // Highlight matching text
    final query = highlightQuery!.toLowerCase();
    final lowerContent = content.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    
    while (true) {
      final index = lowerContent.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: content.substring(start)));
        break;
      }
      
      if (index > start) {
        spans.add(TextSpan(text: content.substring(start, index)));
      }
      
      spans.add(TextSpan(
        text: content.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.6),
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 15.sp,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final isLocalFile = message.isUploading && 
        message.content != null && 
        !message.content!.startsWith('http');
    
    final imageUrl = message.attachment?.s3Url ?? '';
    final heroTag = 'message_image_${message.id}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: message.isUploading ? null : () {
            FullScreenImageViewer.show(
              context,
              imageUrl: isLocalFile ? null : imageUrl,
              localPath: isLocalFile ? message.content : null,
              heroTag: heroTag,
              senderName: isMe ? 'You' : null,
              sentAt: message.createdAt,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: isLocalFile
                      ? Image.file(
                          File(message.content!),
                          width: 200.w,
                          height: 150.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200.w,
                            height: 150.h,
                            color: AppColors.grey200,
                            child: Icon(Icons.broken_image, size: 48.sp),
                          ),
                        )
                      : Image.network(
                          imageUrl,
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
              ),
              // Overlay loading indicator when uploading
              if (message.isUploading)
                Container(
                  width: 200.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (message.content?.isNotEmpty == true && !isLocalFile) ...[
          SizedBox(height: 8.h),
          AppBodyText(
            text: message.content!,
            color: isMe ? Colors.white : null,
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentContent(BuildContext context) {
    final isLocalFile = message.isUploading && message.content != null;
    final fileName = isLocalFile 
        ? message.content!.split('/').last 
        : message.attachment?.fileName ?? 'File';
    final fileSize = isLocalFile 
        ? 'Uploading...' 
        : message.attachment?.formattedSize ?? '';
    
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
          child: message.isUploading
              ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMe ? Colors.white : AppColors.primary,
                    ),
                  ),
                )
              : Icon(
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
                text: fileName,
                color: isMe ? Colors.white : null,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSmallText(
                text: fileSize,
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

          // Text field - compact single line that expands
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 80.h),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A3B3C)
                    : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 2,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryStatic,
                    fontSize: 15.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  isDense: true,
                ),
              ),
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
