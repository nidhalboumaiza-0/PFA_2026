import 'package:equatable/equatable.dart';
import 'message_entity.dart';

/// Participant information in a conversation
class ParticipantEntity extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // 'patient' or 'doctor'
  final bool isOnline;
  final DateTime? lastSeen;

  const ParticipantEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, role, isOnline, lastSeen];
}

/// Last message preview in conversation list
class LastMessageEntity extends Equatable {
  final String content;
  final String senderId;
  final DateTime timestamp;
  final bool isRead;

  const LastMessageEntity({
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.isRead,
  });

  @override
  List<Object?> get props => [content, senderId, timestamp, isRead];
}

/// Conversation entity representing a chat between two users
class ConversationEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final String conversationType; // 'patient_doctor' or 'doctor_doctor'
  final ParticipantEntity? otherParticipant;
  final LastMessageEntity? lastMessage;
  final int unreadCount;
  final bool isActive;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    required this.participantIds,
    required this.conversationType,
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if current user has unread messages
  bool get hasUnread => unreadCount > 0;

  /// Get display name for conversation
  String get displayName => otherParticipant?.name ?? 'Unknown';

  /// Get avatar URL for conversation
  String? get avatarUrl => otherParticipant?.avatarUrl;

  /// Check if other participant is online
  bool get isOnline => otherParticipant?.isOnline ?? false;

  @override
  List<Object?> get props => [
        id,
        participantIds,
        conversationType,
        otherParticipant,
        lastMessage,
        unreadCount,
        isActive,
        isArchived,
        createdAt,
        updatedAt,
      ];
}
