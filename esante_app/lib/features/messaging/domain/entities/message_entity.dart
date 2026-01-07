import 'package:equatable/equatable.dart';

/// File attachment in a message
class AttachmentEntity extends Equatable {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? s3Key;
  final String? s3Url;

  const AttachmentEntity({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.s3Key,
    this.s3Url,
  });

  /// Get file size in human readable format
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if attachment is an image
  bool get isImage => mimeType.startsWith('image/');

  /// Check if attachment is a document
  bool get isDocument => !isImage;

  @override
  List<Object?> get props => [fileName, fileSize, mimeType, s3Key, s3Url];
}

/// Sender information embedded in message
class MessageSenderEntity extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role;

  const MessageSenderEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, role];
}

/// Message types enum
enum MessageType {
  text,
  image,
  document,
  system;

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.document:
        return 'document';
      case MessageType.system:
        return 'system';
    }
  }
}

/// Message entity representing a single message in a conversation
class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String receiverId;
  final String receiverType;
  final MessageType messageType;
  final String? content;
  final AttachmentEntity? attachment;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final MessageSenderEntity? sender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.receiverType,
    this.messageType = MessageType.text,
    this.content,
    this.attachment,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.sender,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Check if message is currently being uploaded
  bool get isUploading => metadata?['uploading'] == true;

  /// Check if message was sent by current user
  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Get display text for message preview
  String get previewText {
    if (isDeleted) return 'Message deleted';
    if (messageType == MessageType.image) return '📷 Photo';
    if (messageType == MessageType.document) return '📎 ${attachment?.fileName ?? 'File'}';
    if (messageType == MessageType.system) return content ?? 'System message';
    return content ?? '';
  }

  /// Get time display string
  String get timeString {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderType,
        receiverId,
        receiverType,
        messageType,
        content,
        attachment,
        isRead,
        readAt,
        isDelivered,
        deliveredAt,
        isEdited,
        editedAt,
        isDeleted,
        sender,
        createdAt,
        updatedAt,
        metadata,
      ];
}
