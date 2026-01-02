import '../../domain/entities/message_entity.dart';

/// Attachment model with JSON serialization
class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.fileName,
    required super.fileSize,
    required super.mimeType,
    super.s3Key,
    super.s3Url,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      fileName: json['fileName'] ?? 'file',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      s3Key: json['s3Key'],
      s3Url: json['s3Url'] ?? json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      's3Key': s3Key,
      's3Url': s3Url,
    };
  }

  AttachmentEntity toEntity() => AttachmentEntity(
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        s3Key: s3Key,
        s3Url: s3Url,
      );
}

/// Message sender model with JSON serialization
class MessageSenderModel extends MessageSenderEntity {
  const MessageSenderModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    required super.role,
  });

  factory MessageSenderModel.fromJson(Map<String, dynamic> json) {
    return MessageSenderModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? json['photoUrl'],
      role: json['role'] ?? json['userType'] ?? 'patient',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
    };
  }

  MessageSenderEntity toEntity() => MessageSenderEntity(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        role: role,
      );
}

/// Message model with JSON serialization
class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
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
    super.sender,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Parse attachment
    AttachmentModel? attachment;
    if (json['attachment'] != null && json['attachment']['fileName'] != null) {
      attachment = AttachmentModel.fromJson(json['attachment']);
    }

    // Parse sender
    MessageSenderModel? sender;
    if (json['sender'] != null) {
      sender = MessageSenderModel.fromJson(json['sender']);
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? 'patient',
      receiverId: json['receiverId'] ?? '',
      receiverType: json['receiverType'] ?? 'doctor',
      messageType: MessageType.fromString(json['messageType'] ?? 'text'),
      content: json['content'],
      attachment: attachment,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      sender: sender,
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
      'conversationId': conversationId,
      'senderId': senderId,
      'senderType': senderType,
      'receiverId': receiverId,
      'receiverType': receiverType,
      'messageType': messageType.value,
      'content': content,
      'attachment': attachment != null
          ? (attachment as AttachmentModel).toJson()
          : null,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'sender': sender != null ? (sender as MessageSenderModel).toJson() : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MessageEntity toEntity() => MessageEntity(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderType: senderType,
        receiverId: receiverId,
        receiverType: receiverType,
        messageType: messageType,
        content: content,
        attachment: attachment,
        isRead: isRead,
        readAt: readAt,
        isDelivered: isDelivered,
        deliveredAt: deliveredAt,
        isEdited: isEdited,
        editedAt: editedAt,
        isDeleted: isDeleted,
        sender: sender,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? receiverType,
    MessageType? messageType,
    String? content,
    AttachmentEntity? attachment,
    bool? isRead,
    DateTime? readAt,
    bool? isDelivered,
    DateTime? deliveredAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    MessageSenderEntity? sender,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
