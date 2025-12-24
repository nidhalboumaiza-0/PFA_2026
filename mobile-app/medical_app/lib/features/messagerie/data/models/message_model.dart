import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';

/// Model for message attachment with JSON serialization
class MessageAttachmentModel extends MessageAttachmentEntity {
  const MessageAttachmentModel({
    super.fileName,
    super.fileSize,
    super.mimeType,
    super.s3Key,
    super.s3Url,
  });

  factory MessageAttachmentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MessageAttachmentModel();
    }
    return MessageAttachmentModel(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      s3Key: json['s3Key'],
      s3Url: json['s3Url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (s3Key != null) 's3Key': s3Key,
      if (s3Url != null) 's3Url': s3Url,
    };
  }
}

/// Model for message with JSON serialization
class MessageModel extends MessageEntity {
  const MessageModel({
    super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderType,
    required super.receiverId,
    required super.receiverType,
    super.messageType,
    super.content,
    super.attachment,
    super.isRead,
    super.readAt,
    super.isDelivered,
    super.deliveredAt,
    super.isEdited,
    super.editedAt,
    super.isDeleted,
    super.deletedAt,
    super.deletedBy,
    super.metadata,
    super.createdAt,
    super.updatedAt,
    super.senderName,
    super.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Extract sender info - handle both backend API and socket formats
    String senderId = '';
    String? senderName = json['senderName']; // Backend API format
    String? senderAvatar;
    if (json['senderId'] is String) {
      senderId = json['senderId'];
    } else if (json['senderId'] is Map) {
      senderId = json['senderId']['_id'] ?? '';
      // Firebase/old format
      senderName ??= '${json['senderId']['nom'] ?? ''} ${json['senderId']['prenom'] ?? ''}'.trim();
      senderAvatar = json['senderId']['photoProfil'];
    }

    // Extract receiver info
    String receiverId = '';
    if (json['receiverId'] is String) {
      receiverId = json['receiverId'];
    } else if (json['receiverId'] is Map) {
      receiverId = json['receiverId']['_id'] ?? '';
    }

    // Parse attachment
    MessageAttachmentModel? attachment;
    if (json['attachment'] != null) {
      attachment = MessageAttachmentModel.fromJson(json['attachment']);
    }

    // Parse metadata
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null) {
      metadata = Map<String, dynamic>.from(json['metadata']);
    }

    return MessageModel(
      id: json['_id'] ?? json['id'],
      conversationId: json['conversationId'] is String
          ? json['conversationId']
          : json['conversationId']?['_id'] ?? '',
      senderId: senderId,
      senderType: json['senderType'] ?? 'patient',
      receiverId: receiverId,
      receiverType: json['receiverType'] ?? 'patient',
      messageType: json['messageType'] ?? 'text',
      content: json['content'],
      attachment: attachment,
      isRead: json['isRead'] ?? false,
      readAt: DateTime.tryParse(json['readAt'] ?? ''),
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: DateTime.tryParse(json['deliveredAt'] ?? ''),
      isEdited: json['isEdited'] ?? false,
      editedAt: DateTime.tryParse(json['editedAt'] ?? ''),
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: DateTime.tryParse(json['deletedAt'] ?? ''),
      deletedBy: json['deletedBy'] is String
          ? json['deletedBy']
          : json['deletedBy']?['_id'],
      metadata: metadata,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderType': senderType,
      'receiverId': receiverId,
      'receiverType': receiverType,
      'messageType': messageType,
      if (content != null) 'content': content,
      if (attachment != null)
        'attachment': (attachment as MessageAttachmentModel).toJson(),
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      'isDelivered': isDelivered,
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deletedBy': deletedBy,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with updated values
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? receiverType,
    String? messageType,
    String? content,
    MessageAttachmentEntity? attachment,
    bool? isRead,
    DateTime? readAt,
    bool? isDelivered,
    DateTime? deliveredAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatar,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      receiverId: receiverId ?? this.receiverId,
      receiverType: receiverType ?? this.receiverType,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      attachment: attachment ?? this.attachment,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }

  /// Create request payload for sending a text message
  static Map<String, dynamic> sendTextRequest({
    required String content,
  }) {
    return {
      'content': content,
      'messageType': 'text',
    };
  }

  /// Create request payload for sending a file message (via Socket.IO)
  static Map<String, dynamic> sendFileRequest({
    required String conversationId,
    required String receiverId,
    required String messageType,
    String? content,
  }) {
    return {
      'conversationId': conversationId,
      'receiverId': receiverId,
      'messageType': messageType,
      if (content != null) 'content': content,
    };
  }
}
