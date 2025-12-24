import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

/// Model for participant type with JSON serialization
class ParticipantTypeModel extends ParticipantTypeEntity {
  const ParticipantTypeModel({
    required super.userId,
    required super.userType,
  });

  factory ParticipantTypeModel.fromJson(Map<String, dynamic> json) {
    return ParticipantTypeModel(
      userId: json['userId'] is String
          ? json['userId']
          : json['userId']?['_id'] ?? '',
      userType: json['userType'] ?? 'patient',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
    };
  }
}

/// Model for last message with JSON serialization
class LastMessageModel extends LastMessageEntity {
  const LastMessageModel({
    super.content,
    super.senderId,
    super.timestamp,
    super.isRead,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LastMessageModel();
    }
    return LastMessageModel(
      content: json['content'],
      senderId: json['senderId'] is String
          ? json['senderId']
          : json['senderId']?['_id'],
      timestamp: _parseDateTime(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (content != null) 'content': content,
      if (senderId != null) 'senderId': senderId,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// Model for conversation with JSON serialization
class ConversationModel extends ConversationEntity {
  const ConversationModel({
    super.id,
    required super.participants,
    super.participantTypes,
    required super.conversationType,
    super.lastMessage,
    super.unreadCount,
    super.isActive,
    super.isArchived,
    super.createdAt,
    super.updatedAt,
    super.otherParticipantId,
    super.otherParticipantName,
    super.otherParticipantAvatar,
    super.otherParticipantType,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Handle backend format which uses 'conversationId' instead of '_id'
    final String? id = json['conversationId']?.toString() ?? json['_id'] ?? json['id'];
    
    // Parse participants - backend may not include this in the response
    List<String> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List).map((p) {
        if (p is String) return p;
        return p['_id']?.toString() ?? '';
      }).toList();
    }

    // Parse participant types
    List<ParticipantTypeModel> participantTypes = [];
    if (json['participantTypes'] != null) {
      participantTypes = (json['participantTypes'] as List)
          .map((pt) => ParticipantTypeModel.fromJson(pt))
          .toList();
    }

    // Parse unread count - backend returns single int, not map
    Map<String, int> unreadCount = {};
    if (json['unreadCount'] != null) {
      if (json['unreadCount'] is Map) {
        (json['unreadCount'] as Map).forEach((key, value) {
          unreadCount[key.toString()] = value is int ? value : 0;
        });
      } else if (json['unreadCount'] is int) {
        // Backend returns a single int for current user's unread count
        if (currentUserId != null) {
          unreadCount[currentUserId] = json['unreadCount'] as int;
        }
      }
    }

    // Extract other participant info from 'recipient' field (backend format)
    String? otherParticipantId;
    String? otherParticipantName;
    String? otherParticipantAvatar;
    String? otherParticipantType;

    // Backend format: recipient object
    if (json['recipient'] != null) {
      final recipient = json['recipient'];
      otherParticipantId = recipient['id']?.toString() ?? recipient['_id']?.toString();
      otherParticipantName = recipient['name']?.toString();
      otherParticipantAvatar = recipient['profilePhoto']?.toString() ?? recipient['photo']?.toString();
      otherParticipantType = recipient['type']?.toString();
      
      // Add to participants if not already there
      if (otherParticipantId != null && !participants.contains(otherParticipantId)) {
        participants.add(otherParticipantId);
      }
      if (currentUserId != null && !participants.contains(currentUserId)) {
        participants.add(currentUserId);
      }
      
      // Add to participantTypes
      if (otherParticipantId != null && otherParticipantType != null) {
        participantTypes.add(ParticipantTypeModel(
          userId: otherParticipantId,
          userType: otherParticipantType,
        ));
      }
    }
    // Firebase/old format: populated participants array
    else if (currentUserId != null && json['participants'] != null) {
      for (var p in json['participants']) {
        if (p is Map) {
          final pId = p['_id']?.toString();
          if (pId != null && pId != currentUserId) {
            otherParticipantId = pId;
            otherParticipantName = '${p['nom'] ?? ''} ${p['prenom'] ?? ''}'.trim();
            otherParticipantAvatar = p['photoProfil'];
            // Find type from participantTypes
            final typeInfo = participantTypes.firstWhere(
              (pt) => pt.userId == pId,
              orElse: () => const ParticipantTypeModel(userId: '', userType: 'patient'),
            );
            otherParticipantType = typeInfo.userType;
            break;
          }
        }
      }
    }

    // Parse last message
    LastMessageModel? lastMessage;
    if (json['lastMessage'] != null) {
      lastMessage = LastMessageModel.fromJson(json['lastMessage']);
    }

    return ConversationModel(
      id: id,
      participants: participants,
      participantTypes: participantTypes,
      conversationType: json['conversationType'] ?? 'patient_doctor',
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      isActive: json['isActive'] ?? true,
      isArchived: json['isArchived'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      otherParticipantId: otherParticipantId,
      otherParticipantName: otherParticipantName,
      otherParticipantAvatar: otherParticipantAvatar,
      otherParticipantType: otherParticipantType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'participants': participants,
      'participantTypes': participantTypes
          .map((pt) => (pt as ParticipantTypeModel).toJson())
          .toList(),
      'conversationType': conversationType,
      if (lastMessage != null)
        'lastMessage': (lastMessage as LastMessageModel).toJson(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'isArchived': isArchived,
    };
  }

  /// Create request payload for starting a new conversation
  static Map<String, dynamic> createRequest({
    required String participantId,
    required String participantType,
  }) {
    return {
      'participantId': participantId,
      'participantType': participantType,
    };
  }
}
