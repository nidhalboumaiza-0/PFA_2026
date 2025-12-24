import 'package:equatable/equatable.dart';

/// Entity representing a message attachment
class MessageAttachmentEntity extends Equatable {
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? s3Key;
  final String? s3Url;

  const MessageAttachmentEntity({
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.s3Key,
    this.s3Url,
  });

  /// Get file size formatted
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  List<Object?> get props => [fileName, fileSize, mimeType, s3Key, s3Url];
}

/// Entity representing a message in a conversation
class MessageEntity extends Equatable {
  final String? id;
  final String conversationId;
  final String senderId;
  final String senderType; // 'patient', 'doctor'
  final String receiverId;
  final String receiverType; // 'patient', 'doctor'
  final String messageType; // 'text', 'image', 'document', 'system'
  final String? content;
  final MessageAttachmentEntity? attachment;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated data for display
  final String? senderName;
  final String? senderAvatar;

  const MessageEntity({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.receiverType,
    this.messageType = 'text',
    this.content,
    this.attachment,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.senderName,
    this.senderAvatar,
  });

  /// Get message timestamp (createdAt)
  DateTime get timestamp => createdAt ?? DateTime.now();

  /// Check if message has attachment
  bool get hasAttachment => attachment != null && attachment!.s3Url != null;

  /// Check if message is an image
  bool get isImage => messageType == 'image';

  /// Check if message is a document
  bool get isDocument => messageType == 'document';

  /// Check if message is a system message
  bool get isSystem => messageType == 'system';

  /// Check if message is a text message
  bool get isText => messageType == 'text';

  /// Get display content (handles deleted messages)
  String get displayContent {
    if (isDeleted) return 'Message deleted';
    return content ?? '';
  }

  /// Check if message can be deleted by user
  bool canUserDelete(String userId) {
    return senderId == userId && !isDeleted;
  }

  /// Check if message is recent (within 24 hours)
  bool get isRecent {
    if (createdAt == null) return false;
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    return createdAt!.isAfter(oneDayAgo);
  }

  /// Get message status for display
  String get statusDisplay {
    if (isRead) return 'read';
    if (isDelivered) return 'delivered';
    return 'sent';
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
        deletedAt,
        deletedBy,
        metadata,
        createdAt,
        updatedAt,
        senderName,
        senderAvatar,
      ];
}
