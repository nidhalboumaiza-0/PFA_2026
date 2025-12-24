import 'package:equatable/equatable.dart';

/// Entity representing participant type info
class ParticipantTypeEntity extends Equatable {
  final String userId;
  final String userType; // 'patient', 'doctor'

  const ParticipantTypeEntity({
    required this.userId,
    required this.userType,
  });

  @override
  List<Object?> get props => [userId, userType];
}

/// Entity representing the last message in a conversation
class LastMessageEntity extends Equatable {
  final String? content;
  final String? senderId;
  final DateTime? timestamp;
  final bool isRead;

  const LastMessageEntity({
    this.content,
    this.senderId,
    this.timestamp,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [content, senderId, timestamp, isRead];
}

/// Entity representing a conversation between users
class ConversationEntity extends Equatable {
  final String? id;
  final List<String> participants; // Array of 2 user IDs
  final List<ParticipantTypeEntity> participantTypes;
  final String conversationType; // 'patient_doctor', 'doctor_doctor'
  final LastMessageEntity? lastMessage;
  final Map<String, int> unreadCount; // Map of userId -> unread count
  final bool isActive;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated data for display (resolved from participants)
  final String? otherParticipantId;
  final String? otherParticipantName;
  final String? otherParticipantAvatar;
  final String? otherParticipantType;

  const ConversationEntity({
    this.id,
    required this.participants,
    this.participantTypes = const [],
    required this.conversationType,
    this.lastMessage,
    this.unreadCount = const {},
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.otherParticipantId,
    this.otherParticipantName,
    this.otherParticipantAvatar,
    this.otherParticipantType,
  });

  /// Check if user is a participant in this conversation
  bool isParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Get the other participant's ID (for current user)
  String? getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Get display name for conversation
  String get displayName => otherParticipantName ?? 'Conversation';

  /// Get last message preview
  String get lastMessagePreview => lastMessage?.content ?? '';

  /// Get last message time
  DateTime? get lastMessageTime => lastMessage?.timestamp;

  /// Check if last message is read
  bool get isLastMessageRead => lastMessage?.isRead ?? true;

  @override
  List<Object?> get props => [
        id,
        participants,
        participantTypes,
        conversationType,
        lastMessage,
        unreadCount,
        isActive,
        isArchived,
        createdAt,
        updatedAt,
        otherParticipantId,
        otherParticipantName,
        otherParticipantAvatar,
        otherParticipantType,
      ];
}
