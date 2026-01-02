import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../injection_container.dart';
import '../presentation/bloc/messaging_bloc.dart';
import '../presentation/bloc/messaging_event.dart';
import '../presentation/bloc/messaging_state.dart';
import '../presentation/screens/chat_screen.dart';

/// Helper class to start messaging with a user
class MessagingHelper {
  MessagingHelper._();

  /// Start or open a conversation with a user
  /// 
  /// [recipientId] - The ID of the user to message
  /// [recipientType] - 'patient' or 'doctor'
  /// [recipientName] - Display name for the chat screen
  /// [recipientAvatarUrl] - Optional avatar URL
  static Future<void> startConversation({
    required BuildContext context,
    required String recipientId,
    required String recipientType,
    required String recipientName,
    String? recipientAvatarUrl,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Create a temporary bloc to create/get the conversation
    final bloc = sl<MessagingBloc>();
    
    bloc.add(CreateConversation(
      recipientId: recipientId,
      recipientType: recipientType,
    ));

    // Listen for the result
    await for (final state in bloc.stream) {
      if (state is ConversationCreated) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // Navigate to chat screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: state.conversation.id,
                recipientId: recipientId,
                recipientName: recipientName,
                recipientAvatarUrl: recipientAvatarUrl,
              ),
            ),
          );
        }
        break;
      } else if (state is ConversationError) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          AppSnackbar.showError(context, state.message);
        }
        break;
      }
    }
  }
}

/// Button widget to message a user
class MessageUserButton extends StatelessWidget {
  final String recipientId;
  final String recipientType;
  final String recipientName;
  final String? recipientAvatarUrl;
  final bool expanded;

  const MessageUserButton({
    super.key,
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    this.recipientAvatarUrl,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return CustomButton(
        text: 'Send Message',
        icon: Icons.chat_bubble_outline,
        onPressed: () => _startConversation(context),
        type: ButtonType.outlined,
      );
    }

    return IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      tooltip: 'Send Message',
      onPressed: () => _startConversation(context),
    );
  }

  void _startConversation(BuildContext context) {
    MessagingHelper.startConversation(
      context: context,
      recipientId: recipientId,
      recipientType: recipientType,
      recipientName: recipientName,
      recipientAvatarUrl: recipientAvatarUrl,
    );
  }
}

/// Floating action button for messaging
class MessageFloatingButton extends StatelessWidget {
  final String recipientId;
  final String recipientType;
  final String recipientName;
  final String? recipientAvatarUrl;

  const MessageFloatingButton({
    super.key,
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    this.recipientAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'message_fab_$recipientId',
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.chat, color: Colors.white),
      onPressed: () => MessagingHelper.startConversation(
        context: context,
        recipientId: recipientId,
        recipientType: recipientType,
        recipientName: recipientName,
        recipientAvatarUrl: recipientAvatarUrl,
      ),
    );
  }
}
