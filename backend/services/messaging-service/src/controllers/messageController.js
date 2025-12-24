import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';
import { publishToKafka } from '../../../../shared/kafka/producer.js';
import { KAFKA_TOPICS } from '../../../../shared/kafka/topics.js';
import {
  getUserInfo,
  formatConversationForResponse,
  formatMessageForResponse,
  calculateUnreadCount,
  buildConversationQuery,
  uploadFileToS3,
  validateFileAttachment,
  getUserOnlineStatus,
  determineConversationType,
  canUserMessageRecipient,
  calculatePagination,
} from '../utils/messageHelpers.js';

/**
 * Create or get existing conversation
 * POST /api/v1/messages/conversations
 */
export const createOrGetConversation = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const currentUserRole = req.user.role;
    const { recipientId, recipientType } = req.body;

    // Validate recipient ID
    if (currentUserId === recipientId) {
      return res.status(400).json({ message: 'Cannot create conversation with yourself' });
    }

    // Get recipient info from User Service
    const recipientInfo = await getUserInfo(recipientId, req.headers.authorization.split(' ')[1]);
    if (!recipientInfo) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    // Verify recipient type matches
    if (recipientInfo.role !== recipientType) {
      return res.status(400).json({ message: 'Recipient type mismatch' });
    }

    // Check if user can message recipient
    const canMessage = await canUserMessageRecipient(
      currentUserId,
      currentUserRole,
      recipientId,
      recipientType
    );

    if (!canMessage) {
      return res.status(403).json({ message: 'You cannot message this user' });
    }

    // Sort participants to ensure consistent ordering
    const participants = [currentUserId, recipientId].sort((a, b) =>
      a.toString().localeCompare(b.toString())
    );

    // Check if conversation already exists
    let conversation = await Conversation.findOne({ participants });

    if (conversation) {
      // Return existing conversation
      const formattedConversation = await formatConversationForResponse(
        conversation,
        currentUserId,
        recipientInfo,
        req.app.get('onlineUsers')
      );

      return res.status(200).json({
        message: 'Conversation retrieved successfully',
        data: formattedConversation,
      });
    }

    // Create new conversation
    const conversationType = determineConversationType(currentUserRole, recipientType);

    conversation = new Conversation({
      participants,
      participantTypes: [
        { userId: currentUserId, userType: currentUserRole },
        { userId: recipientId, userType: recipientType },
      ],
      conversationType,
    });

    await conversation.save();

    const formattedConversation = await formatConversationForResponse(
      conversation,
      currentUserId,
      recipientInfo,
      req.app.get('onlineUsers')
    );

    res.status(201).json({
      message: 'Conversation created successfully',
      data: formattedConversation,
    });
  } catch (error) {
    console.error('Error in createOrGetConversation:', error);
    res.status(500).json({ message: 'Server error while creating conversation' });
  }
};

/**
 * Get user's conversations
 * GET /api/v1/messages/conversations
 */
export const getUserConversations = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { type, page, limit } = req.query;

    // Build query
    const query = buildConversationQuery(currentUserId, { type });

    // Count total conversations
    const totalConversations = await Conversation.countDocuments(query);

    // Get conversations with pagination
    const skip = (page - 1) * limit;
    const conversations = await Conversation.find(query)
      .sort({ 'lastMessage.timestamp': -1, updatedAt: -1 })
      .skip(skip)
      .limit(limit);

    // Format conversations with recipient info
    const token = req.headers.authorization.split(' ')[1];
    const onlineUsersMap = req.app.get('onlineUsers');

    const formattedConversations = await Promise.all(
      conversations.map(async (conv) => {
        const otherParticipantId = conv.getOtherParticipant(currentUserId);
        const recipientInfo = await getUserInfo(otherParticipantId, token);

        if (!recipientInfo) {
          return null;
        }

        return formatConversationForResponse(conv, currentUserId, recipientInfo, onlineUsersMap);
      })
    );

    // Filter out null values (users that couldn't be fetched)
    const validConversations = formattedConversations.filter((conv) => conv !== null);

    // Calculate pagination
    const pagination = calculatePagination(page, limit, totalConversations);

    res.status(200).json({
      message: 'Conversations retrieved successfully',
      data: validConversations,
      pagination,
    });
  } catch (error) {
    console.error('Error in getUserConversations:', error);
    res.status(500).json({ message: 'Server error while fetching conversations' });
  }
};

/**
 * Get conversation messages (history)
 * GET /api/v1/messages/conversations/:conversationId/messages
 */
export const getConversationMessages = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { conversationId } = req.params;
    const { page, limit, before } = req.query;

    // Find conversation and verify user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.isParticipant(currentUserId)) {
      return res.status(403).json({ message: 'You are not part of this conversation' });
    }

    // Build query for messages
    const query = {
      conversationId,
      isDeleted: false,
    };

    // If 'before' parameter is provided, get messages before that message
    if (before) {
      const beforeMessage = await Message.findById(before);
      if (beforeMessage) {
        query.createdAt = { $lt: beforeMessage.createdAt };
      }
    }

    // Count total messages
    const totalMessages = await Message.countDocuments(query);

    // Get messages (sorted desc for pagination, will reverse later)
    const skip = (page - 1) * limit;
    const messages = await Message.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Reverse to show chronological order (oldest first)
    messages.reverse();

    // Mark unread messages as delivered if they're for current user
    const unreadMessageIds = messages
      .filter((msg) => msg.receiverId.toString() === currentUserId && !msg.isDelivered)
      .map((msg) => msg._id);

    if (unreadMessageIds.length > 0) {
      await Message.updateMany(
        { _id: { $in: unreadMessageIds } },
        { $set: { isDelivered: true, deliveredAt: new Date() } }
      );

      // Publish Kafka event for each delivered message
      for (const messageId of unreadMessageIds) {
        await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_DELIVERED, {
          eventType: 'message.delivered',
          messageId: messageId.toString(),
          deliveredAt: Date.now(),
        });
      }
    }

    // Get unique sender IDs
    const senderIds = [...new Set(messages.map((msg) => msg.senderId.toString()))];

    // Fetch sender info for all senders
    const token = req.headers.authorization.split(' ')[1];
    const sendersInfo = await Promise.all(
      senderIds.map((senderId) => getUserInfo(senderId, token))
    );

    const sendersMap = {};
    sendersInfo.forEach((sender) => {
      if (sender) {
        sendersMap[sender._id || sender.id] = sender;
      }
    });

    // Format messages
    const formattedMessages = messages.map((msg) => {
      const senderInfo = sendersMap[msg.senderId.toString()];
      return formatMessageForResponse(msg, senderInfo);
    });

    // Calculate pagination
    const pagination = calculatePagination(page, limit, totalMessages);
    pagination.hasMore = page * limit < totalMessages;

    res.status(200).json({
      message: 'Messages retrieved successfully',
      data: {
        conversationId,
        messages: formattedMessages,
        pagination,
      },
    });
  } catch (error) {
    console.error('Error in getConversationMessages:', error);
    res.status(500).json({ message: 'Server error while fetching messages' });
  }
};

/**
 * Mark messages as read (REST endpoint)
 * PUT /api/v1/messages/conversations/:conversationId/mark-read
 */
export const markMessagesAsRead = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { conversationId } = req.params;
    const { messageIds } = req.body;

    // Find conversation and verify user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.isParticipant(currentUserId)) {
      return res.status(403).json({ message: 'You are not part of this conversation' });
    }

    // Mark messages as read
    const result = await Message.markMultipleAsRead(messageIds, currentUserId);

    // Reset unread count for user in conversation
    conversation.resetUnreadCount(currentUserId);
    await conversation.save();

    // Get messages to find senders
    const messages = await Message.find({ _id: { $in: messageIds } });
    const senderIds = [...new Set(messages.map((msg) => msg.senderId.toString()))];

    // Emit Socket.IO event to senders
    const io = req.app.get('io');
    const onlineUsersMap = req.app.get('onlineUsers');

    for (const senderId of senderIds) {
      if (senderId !== currentUserId && onlineUsersMap.has(senderId)) {
        io.to(senderId).emit('messages_read', {
          conversationId,
          messageIds,
          readBy: currentUserId,
          readAt: new Date(),
        });
      }
    }

    // Publish Kafka event
    await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_READ, {
      eventType: 'message.read',
      conversationId,
      messageIds,
      readBy: currentUserId,
      readAt: Date.now(),
    });

    res.status(200).json({
      message: `${result.modifiedCount} messages marked as read`,
    });
  } catch (error) {
    console.error('Error in markMessagesAsRead:', error);
    res.status(500).json({ message: 'Server error while marking messages as read' });
  }
};

/**
 * Send message with file attachment
 * POST /api/v1/messages/conversations/:conversationId/send-file
 */
export const sendFileMessage = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const currentUserRole = req.user.role;
    const { conversationId } = req.params;
    const { receiverId, messageType, caption } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: 'No file provided' });
    }

    // Find conversation and verify user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.isParticipant(currentUserId)) {
      return res.status(403).json({ message: 'You are not part of this conversation' });
    }

    // Validate receiver is the other participant
    const otherParticipant = conversation.getOtherParticipant(currentUserId);
    if (otherParticipant.toString() !== receiverId) {
      return res.status(400).json({ message: 'Invalid receiver ID' });
    }

    // Validate file
    validateFileAttachment(file);

    // Upload file to S3
    const attachmentData = await uploadFileToS3(file, conversationId);

    // Get receiver type from participantTypes
    const receiverType = conversation.participantTypes.find(
      (pt) => pt.userId.toString() === receiverId
    )?.userType;

    // Create message
    const message = new Message({
      conversationId,
      senderId: currentUserId,
      senderType: currentUserRole,
      receiverId,
      receiverType,
      messageType,
      content: caption || `Sent a ${messageType}`,
      attachment: attachmentData,
    });

    await message.save();

    // Update conversation last message
    conversation.updateLastMessage(message);
    conversation.incrementUnreadCount(receiverId);
    await conversation.save();

    // Get sender info
    const token = req.headers.authorization.split(' ')[1];
    const senderInfo = await getUserInfo(currentUserId, token);

    // Emit Socket.IO event to receiver
    const io = req.app.get('io');
    const onlineUsersMap = req.app.get('onlineUsers');

    const formattedMessage = formatMessageForResponse(message, senderInfo);

    if (onlineUsersMap.has(receiverId)) {
      io.to(receiverId).emit('new_message', formattedMessage);

      // Mark as delivered immediately
      message.markAsDelivered();
      await message.save();
    }

    // Publish Kafka event
    await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_SENT, {
      eventType: 'message.sent',
      messageId: message._id.toString(),
      conversationId,
      senderId: currentUserId,
      receiverId,
      messageType,
      timestamp: Date.now(),
    });

    res.status(201).json({
      message: 'File sent successfully',
      data: formattedMessage,
    });
  } catch (error) {
    console.error('Error in sendFileMessage:', error);
    res.status(500).json({ message: error.message || 'Server error while sending file' });
  }
};

/**
 * Delete message (soft delete)
 * DELETE /api/v1/messages/:messageId
 */
export const deleteMessage = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { messageId } = req.params;

    // Find message
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    // Verify user can delete (only sender can delete)
    if (!message.canUserDelete(currentUserId)) {
      return res.status(403).json({ message: 'You can only delete your own messages' });
    }

    // Check if message is recent (optional: within 24 hours)
    // if (!message.isRecent()) {
    //   return res.status(403).json({ message: 'Cannot delete messages older than 24 hours' });
    // }

    // Soft delete
    message.softDelete(currentUserId);
    await message.save();

    // Emit Socket.IO event to receiver
    const io = req.app.get('io');
    const onlineUsersMap = req.app.get('onlineUsers');

    if (onlineUsersMap.has(message.receiverId.toString())) {
      io.to(message.receiverId.toString()).emit('message_deleted', {
        messageId: message._id,
        conversationId: message.conversationId,
        deletedAt: message.deletedAt,
      });
    }

    res.status(200).json({
      message: 'Message deleted successfully',
    });
  } catch (error) {
    console.error('Error in deleteMessage:', error);
    res.status(500).json({ message: 'Server error while deleting message' });
  }
};

/**
 * Get unread message count
 * GET /api/v1/messages/unread-count
 */
export const getUnreadCount = async (req, res) => {
  try {
    const currentUserId = req.user.userId;

    // Calculate unread count
    const { totalUnread, byConversation } = await calculateUnreadCount(currentUserId);

    // Get recipient names for conversations with unread messages
    const token = req.headers.authorization.split(' ')[1];
    const formattedByConversation = await Promise.all(
      byConversation.map(async (item) => {
        const recipientInfo = await getUserInfo(item.otherParticipantId, token);
        return {
          conversationId: item.conversationId,
          recipientName: recipientInfo?.fullName || recipientInfo?.name || 'Unknown',
          unreadCount: item.unreadCount,
        };
      })
    );

    res.status(200).json({
      message: 'Unread count retrieved successfully',
      data: {
        totalUnread,
        byConversation: formattedByConversation,
      },
    });
  } catch (error) {
    console.error('Error in getUnreadCount:', error);
    res.status(500).json({ message: 'Server error while fetching unread count' });
  }
};

/**
 * Search messages
 * GET /api/v1/messages/search
 */
export const searchMessages = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { query, conversationId, page, limit } = req.query;

    // Build search query
    const searchQuery = {
      $or: [{ senderId: currentUserId }, { receiverId: currentUserId }],
      $text: { $search: query },
      isDeleted: false,
    };

    // Filter by conversation if specified
    if (conversationId) {
      searchQuery.conversationId = conversationId;
    }

    // Count total matching messages
    const totalMessages = await Message.countDocuments(searchQuery);

    // Get messages with pagination
    const skip = (page - 1) * limit;
    const messages = await Message.find(searchQuery)
      .sort({ score: { $meta: 'textScore' }, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get unique sender IDs
    const senderIds = [...new Set(messages.map((msg) => msg.senderId.toString()))];

    // Fetch sender info
    const token = req.headers.authorization.split(' ')[1];
    const sendersInfo = await Promise.all(
      senderIds.map((senderId) => getUserInfo(senderId, token))
    );

    const sendersMap = {};
    sendersInfo.forEach((sender) => {
      if (sender) {
        sendersMap[sender._id || sender.id] = sender;
      }
    });

    // Format messages
    const formattedMessages = messages.map((msg) => {
      const senderInfo = sendersMap[msg.senderId.toString()];
      return formatMessageForResponse(msg, senderInfo);
    });

    // Calculate pagination
    const pagination = calculatePagination(page, limit, totalMessages);

    res.status(200).json({
      message: 'Search results retrieved successfully',
      data: {
        query,
        messages: formattedMessages,
        pagination,
      },
    });
  } catch (error) {
    console.error('Error in searchMessages:', error);
    res.status(500).json({ message: 'Server error while searching messages' });
  }
};

/**
 * Get user online status
 * GET /api/v1/messages/users/:userId/online-status
 */
export const getOnlineStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const onlineUsersMap = req.app.get('onlineUsers');

    const isOnline = getUserOnlineStatus(userId, onlineUsersMap);

    res.status(200).json({
      message: 'Online status retrieved successfully',
      data: {
        userId,
        isOnline,
      },
    });
  } catch (error) {
    console.error('Error in getOnlineStatus:', error);
    res.status(500).json({ message: 'Server error while fetching online status' });
  }
};
