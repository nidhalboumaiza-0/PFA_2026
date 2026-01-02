import '../../domain/entities/conversation_entity.dart';

/// Participant model with JSON serialization
class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    required super.role,
    super.isOnline,
    super.lastSeen,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? json['photoUrl'],
      role: json['role'] ?? json['userType'] ?? 'patient',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  ParticipantEntity toEntity() => ParticipantEntity(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        role: role,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
}

/// Last message model with JSON serialization
class LastMessageModel extends LastMessageEntity {
  const LastMessageModel({
    required super.content,
    required super.senderId,
    required super.timestamp,
    required super.isRead,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  LastMessageEntity toEntity() => LastMessageEntity(
        content: content,
        senderId: senderId,
        timestamp: timestamp,
        isRead: isRead,
      );
}

/// Conversation model with JSON serialization
class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.conversationType,
    super.otherParticipant,
    super.lastMessage,
    super.unreadCount,
    super.isActive,
    super.isArchived,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Parse participant IDs
    final participantIds = json['participants'] != null
        ? List<String>.from(json['participants'].map((p) => p is String ? p : p['_id'] ?? p['id'] ?? ''))
        : <String>[];

    // Parse other participant
    ParticipantModel? otherParticipant;
    if (json['otherParticipant'] != null) {
      otherParticipant = ParticipantModel.fromJson(json['otherParticipant']);
    } else if (json['recipient'] != null) {
      otherParticipant = ParticipantModel.fromJson(json['recipient']);
    }

    // Parse last message
    LastMessageModel? lastMessage;
    if (json['lastMessage'] != null && json['lastMessage']['content'] != null) {
      lastMessage = LastMessageModel.fromJson(json['lastMessage']);
    }

    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      participantIds: participantIds,
      conversationType: json['conversationType'] ?? 'patient_doctor',
      otherParticipant: otherParticipant,
      lastMessage: lastMessage,
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isArchived: json['isArchived'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participantIds,
      'conversationType': conversationType,
      'otherParticipant': otherParticipant != null
          ? (otherParticipant as ParticipantModel).toJson()
          : null,
      'lastMessage':
          lastMessage != null ? (lastMessage as LastMessageModel).toJson() : null,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationEntity toEntity() => ConversationEntity(
        id: id,
        participantIds: participantIds,
        conversationType: conversationType,
        otherParticipant: otherParticipant,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        isActive: isActive,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
