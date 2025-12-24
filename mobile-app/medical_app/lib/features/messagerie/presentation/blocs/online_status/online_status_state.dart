import 'package:equatable/equatable.dart';

/// Represents a user's online status
class UserOnlineStatus {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserOnlineStatus({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  UserOnlineStatus copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserOnlineStatus(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// State for online status tracking
class OnlineStatusState extends Equatable {
  final Map<String, UserOnlineStatus> onlineUsers;

  const OnlineStatusState({
    this.onlineUsers = const {},
  });

  /// Check if a specific user is online
  bool isUserOnline(String userId) {
    return onlineUsers[userId]?.isOnline ?? false;
  }

  /// Get last seen time for a user
  DateTime? getLastSeen(String userId) {
    return onlineUsers[userId]?.lastSeen;
  }

  /// Get status for a specific user
  UserOnlineStatus? getUserStatus(String userId) {
    return onlineUsers[userId];
  }

  OnlineStatusState copyWith({
    Map<String, UserOnlineStatus>? onlineUsers,
  }) {
    return OnlineStatusState(
      onlineUsers: onlineUsers ?? this.onlineUsers,
    );
  }

  @override
  List<Object?> get props => [onlineUsers];
}
