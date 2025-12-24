import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/message/message_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_cubit.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ChatScreen displays the messaging interface for a conversation
class ChatScreen extends StatefulWidget {
  final String chatId; // Unique ID of the conversation
  final String userName; // Name of the recipient
  final String recipientId; // ID of the recipient user

  const ChatScreen({
    required this.chatId,
    required this.userName,
    required this.recipientId,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  
  String _currentUserId = '';
  bool _isCurrentUserDoctor = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final userJson = sharedPreferences.getString('CACHED_USER');
      if (userJson == null) {
        showErrorSnackBar(context, context.tr('messaging.user_not_authenticated'));
        Navigator.pop(context);
        return;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _currentUserId = userMap['id'] as String? ?? '';
        _isCurrentUserDoctor =
            userMap.containsKey('speciality') &&
            userMap.containsKey('numLicence');
        _isInitialized = true;
      });

      print(
        'ChatScreen initialized with chatId: ${widget.chatId}, userName: ${widget.userName}, recipientId: ${widget.recipientId}',
      );

      // Fetch messages
      context.read<MessageBloc>().add(
        FetchMessagesEvent(conversationId: widget.chatId),
      );

      // Mark messages as read
      _markMessagesAsRead();
    } catch (e) {
      print('Error initializing user: $e');
      showErrorSnackBar(context, context.tr('messaging.error_loading_user'));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Marks all unread messages as read
  void _markMessagesAsRead() {
    if (_currentUserId.isNotEmpty) {
      context.read<MessageBloc>().add(
        MarkMessagesAsReadEvent(conversationId: widget.chatId),
      );
    }
  }

  /// Sends a text message
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      print('Sending text message: ${_messageController.text}');
      context.read<MessageBloc>().add(
        SendMessageEvent(
          conversationId: widget.chatId,
          receiverId: widget.recipientId,
          content: _messageController.text.trim(),
          type: 'text',
        ),
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  /// Picks multiple images and shows preview
  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
      print('Selected ${images.length} images');
      _showImagePreview();
    }
  }

  /// Shows a modal bottom sheet to preview selected images
  void _showImagePreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(16.w),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Text(
                    context.tr('selected_images').replaceAll(
                      '{count}',
                      _selectedImages.length.toString(),
                    ),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final image = _selectedImages[index];
                        return Stack(
                          children: [
                            Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                              width: 100.w,
                              height: 100.h,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  });
                                  if (_selectedImages.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  color: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed:
                        _selectedImages.isEmpty
                            ? null
                            : () {
                              _sendImages();
                              Navigator.pop(context);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      context.tr('send') + ' (${_selectedImages.length})',
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _selectedImages = [];
      });
    });
  }

  /// Sends all selected images as individual messages
  void _sendImages() {
    for (var image in _selectedImages) {
      final file = File(image.path);
      context.read<MessageBloc>().add(
        SendMessageEvent(
          conversationId: widget.chatId,
          receiverId: widget.recipientId,
          content: '',
          type: 'image',
          file: file,
        ),
      );
    }
    _scrollToBottom();
  }

  /// Picks and sends a file
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      print('Sending file: ${result.files.single.name}');
      context.read<MessageBloc>().add(
        SendMessageEvent(
          conversationId: widget.chatId,
          receiverId: widget.recipientId,
          content: '',
          type: 'document',
          file: file,
        ),
      );
      _scrollToBottom();
    }
  }

  /// Scrolls to the latest message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Displays an image in a dialog
  void _viewMedia(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: CachedNetworkImage(
              imageUrl: url,
              placeholder:
                  (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) =>
                      Icon(Icons.error, size: 50.sp, color: AppColors.grey),
              fit: BoxFit.contain,
            ),
          ),
    );
  }

  /// Placeholder for file download
  void _downloadFile(String url, String fileName) {
    showErrorSnackBar(context, context.tr('messaging.file_download_not_implemented'));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.userName,
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            // Online status subtitle
            BlocBuilder<OnlineStatusCubit, OnlineStatusState>(
              builder: (context, onlineState) {
                final isOnline = onlineState.isUserOnline(widget.recipientId);
                final lastSeenText = context.read<OnlineStatusCubit>().getLastSeenText(
                  widget.recipientId,
                  onlineText: context.tr('online') ?? 'Online',
                );
                
                if (lastSeenText.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Row(
                  children: [
                    if (isOnline)
                      Container(
                        width: 8.w,
                        height: 8.h,
                        margin: EdgeInsets.only(right: 4.w),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      lastSeenText,
                      style: GoogleFonts.raleway(
                        fontSize: 12.sp,
                        color: isOnline ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 2,
      ),
      body: BlocConsumer<MessageBloc, MessageState>(
        listener: (context, state) {
          if (state is MessageError) {
            showErrorSnackBar(context, state.message);
          }
          if (state is MessageLoaded && state.errorMessage != null) {
            showErrorSnackBar(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          List<MessageEntity> messages = [];
          bool isLoading = false;
          bool isTyping = false;

          if (state is MessageLoading) {
            isLoading = state.isInitialLoad;
            messages = state.messages ?? [];
          } else if (state is MessageLoaded) {
            messages = state.messages;
            isTyping = state.isTyping;
          } else if (state is MessageError) {
            return _buildErrorView(state.message);
          }

          return Column(
            children: [
              // Typing indicator
              if (isTyping)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Text(
                        '${widget.userName} ${context.tr('is_typing')}',
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    isLoading && messages.isEmpty
                        ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                        : messages.isEmpty
                        ? _buildEmptyView()
                        : _buildMessageList(messages),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: () {
        context.read<MessageBloc>().add(
          FetchMessagesEvent(
            conversationId: widget.chatId,
            forceReload: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return EmptyStateWidget(
      message: context.tr('no_messages_yet'),
      description: context.tr('start_conversation'),
    );
  }

  Widget _buildMessageList(List<MessageEntity> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _currentUserId;

        // Add date header if needed
        final showDateHeader =
            index == messages.length - 1 ||
            !_isSameDay(
              message.timestamp ?? DateTime.now(),
              messages[index + 1].timestamp ?? DateTime.now(),
            );

        return Column(
          children: [
            if (showDateHeader)
              _buildDateHeader(message.timestamp ?? DateTime.now()),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isMe) {
    return Align(
      key: ValueKey(message.id),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 8.h,
            bottom: 8.h,
            left: isMe ? 64.w : 8.w,
            right: isMe ? 8.w : 64.w,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isMe ? 16.r : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Text message
              if (message.messageType == 'text' && (message.content?.isNotEmpty ?? false))
                Text(
                  message.content!,
                  style: GoogleFonts.raleway(
                    fontSize: 15.sp,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
              // Image message
              if (message.messageType == 'image' &&
                  message.attachment?.s3Url != null)
                GestureDetector(
                  onTap: () => _viewMedia(message.attachment!.s3Url!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: message.attachment!.s3Url!,
                      width: 200.w,
                      height: 200.h,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 200.w,
                            height: 200.h,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: CircularProgressIndicator(
                                color:
                                    isMe
                                        ? Colors.white70
                                        : AppColors.primaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: 200.w,
                            height: 200.h,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 40.sp,
                                color: Colors.red,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              // Document message
              if (message.messageType == 'document' &&
                  message.attachment?.fileName != null)
                GestureDetector(
                  onTap:
                      () => _downloadFile(
                        message.attachment!.s3Url ?? '',
                        message.attachment!.fileName!,
                      ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description,
                          size: 20.sp,
                          color: isMe ? Colors.white : AppColors.primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            message.attachment!.fileName!,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.download,
                          size: 18.sp,
                          color: isMe ? Colors.white70 : AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(
                      message.timestamp ?? DateTime.now(),
                    ),
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    _buildMessageStatusIcon(message),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageEntity message) {
    if (message.isRead) {
      return Icon(Icons.done_all, size: 14.sp, color: Colors.blue.shade300);
    } else if (message.isDelivered) {
      return Icon(
        Icons.done_all,
        size: 14.sp,
        color: Colors.white.withOpacity(0.7),
      );
    } else {
      return Icon(
        Icons.check,
        size: 14.sp,
        color: Colors.white.withOpacity(0.7),
      );
    }
  }

  Widget _buildDateHeader(DateTime messageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      messageTime.year,
      messageTime.month,
      messageTime.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = context.tr('today');
    } else if (messageDate == yesterday) {
      dateText = context.tr('yesterday');
    } else {
      dateText = DateFormat('EEEE, d MMMM').format(messageTime);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            dateText,
            style: GoogleFonts.raleway(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.image,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
              onPressed: _pickFile,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: context.tr('type_a_message'),
                  hintStyle: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                ),
                style: GoogleFonts.raleway(fontSize: 14.sp, color: Colors.black87),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  // Send typing indicator
                  context.read<MessageBloc>().add(
                    SendTypingEvent(
                      recipientId: widget.recipientId,
                      conversationId: widget.chatId,
                      isTyping: value.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 20.sp),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
