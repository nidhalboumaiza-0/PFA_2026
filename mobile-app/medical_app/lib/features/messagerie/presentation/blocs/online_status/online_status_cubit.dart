import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';
import 'online_status_state.dart';

/// Cubit for managing real-time online status of users
class OnlineStatusCubit extends Cubit<OnlineStatusState> {
  final ConversationRepository repository;
  StreamSubscription? _onlineStatusSubscription;

  OnlineStatusCubit({
    required this.repository,
  }) : super(const OnlineStatusState()) {
    _listenToOnlineStatus();
  }

  /// Start listening to online status stream from socket
  void _listenToOnlineStatus() {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = repository.onlineStatusStream.listen(
      (data) {
        try {
          final userId = data['userId'] as String?;
          final isOnline = data['isOnline'] as bool? ?? false;
          final lastSeenStr = data['lastSeen'] as String?;
          final timestampStr = data['timestamp'] as String?;

          if (userId == null || userId.isEmpty) return;

          DateTime? lastSeen;
          if (lastSeenStr != null) {
            lastSeen = DateTime.tryParse(lastSeenStr);
          } else if (!isOnline && timestampStr != null) {
            lastSeen = DateTime.tryParse(timestampStr);
          } else if (!isOnline) {
            lastSeen = DateTime.now();
          }

          _updateUserStatus(userId, isOnline, lastSeen);
        } catch (e) {
          debugPrint('OnlineStatusCubit: Error parsing online status: $e');
        }
      },
      onError: (error) {
        debugPrint('OnlineStatusCubit: Stream error: $error');
      },
    );
  }

  /// Update a user's online status
  void _updateUserStatus(String userId, bool isOnline, DateTime? lastSeen) {
    final updatedUsers = Map<String, UserOnlineStatus>.from(state.onlineUsers);
    
    updatedUsers[userId] = UserOnlineStatus(
      userId: userId,
      isOnline: isOnline,
      lastSeen: lastSeen ?? updatedUsers[userId]?.lastSeen,
    );

    emit(state.copyWith(onlineUsers: updatedUsers));
    debugPrint('OnlineStatusCubit: User $userId is now ${isOnline ? "online" : "offline"}');
  }

  /// Manually check and fetch online status for a specific user
  Future<bool> checkUserOnlineStatus(String userId) async {
    final result = await repository.getOnlineStatus(userId);
    
    return result.fold(
      (failure) {
        debugPrint('OnlineStatusCubit: Failed to fetch online status for $userId');
        return false;
      },
      (isOnline) {
        _updateUserStatus(userId, isOnline, isOnline ? null : DateTime.now());
        return isOnline;
      },
    );
  }

  /// Check online status for multiple users
  Future<void> checkMultipleUsersStatus(List<String> userIds) async {
    for (final userId in userIds) {
      await checkUserOnlineStatus(userId);
    }
  }

  /// Check if a user is online (from cached state)
  bool isUserOnline(String userId) {
    return state.isUserOnline(userId);
  }

  /// Get formatted "last seen" string
  String getLastSeenText(String userId, {String onlineText = 'Online', String Function(Duration)? formatDuration}) {
    final status = state.getUserStatus(userId);
    
    if (status == null) {
      return '';
    }
    
    if (status.isOnline) {
      return onlineText;
    }
    
    final lastSeen = status.lastSeen;
    if (lastSeen == null) {
      return '';
    }

    final difference = DateTime.now().difference(lastSeen);
    
    if (formatDuration != null) {
      return formatDuration(difference);
    }

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    } else {
      return 'Last seen ${difference.inDays} days ago';
    }
  }

  @override
  Future<void> close() {
    _onlineStatusSubscription?.cancel();
    return super.close();
  }
}
