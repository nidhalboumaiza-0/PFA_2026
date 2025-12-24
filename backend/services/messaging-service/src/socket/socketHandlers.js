import jwt from 'jsonwebtoken';
import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';
import { publishToKafka } from '../../../../shared/kafka/producer.js';
import { KAFKA_TOPICS } from '../../../../shared/kafka/topics.js';
import {
  getUserInfo,
  getContactsForUser,
  formatMessageForResponse,
} from '../utils/messageHelpers.js';
import {
  sendMessageSocketSchema,
  typingEventSchema,
  markAsReadSocketSchema,
} from '../validators/messageValidator.js';
import { setUserOnline, setUserOffline, publishTypingStatus } from '../services/presenceService.js';
import { getConfig } from '../../../../shared/index.js';

/**
 * Initialize Socket.IO with authentication and event handlers
 */
export const initializeSocketIO = (io) => {
  // Map to track online users: userId -> socketId
  const onlineUsers = new Map();

  // Socket.IO authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication token required'));
      }

      // Verify JWT token
      const decoded = jwt.verify(token, getConfig('JWT_SECRET'));
      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      socket.token = token;

      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      next(new Error('Authentication failed'));
    }
  });

  // Connection event
  io.on('connection', async (socket) => {
    console.log(`✅ User connected: ${socket.userId} (${socket.userRole})`);

    // Add user to online users map
    onlineUsers.set(socket.userId, socket.id);

    // Set user as online in Redis (for cross-instance presence)
    try {
      await setUserOnline(socket.userId, {
        socketId: socket.id,
        role: socket.userRole
      });
    } catch (error) {
      console.warn('Could not set Redis presence:', error.message);
    }

    // User joins their own room for private messaging
    socket.join(socket.userId);

    // Broadcast online status to user's contacts
    try {
      const contacts = await getContactsForUser(socket.userId);
      contacts.forEach((contactId) => {
        io.to(contactId).emit('user_online', {
          userId: socket.userId,
          timestamp: Date.now(),
        });
      });
    } catch (error) {
      console.error('Error broadcasting online status:', error.message);
    }

    // Handle send_message event
    socket.on('send_message', async (payload) => {
      try {
        // Validate payload
        const { error, value } = sendMessageSocketSchema.validate(payload);
        if (error) {
          return socket.emit('error', {
            event: 'send_message',
            message: error.details[0].message,
          });
        }

        const { conversationId, receiverId, messageType, content, tempId, metadata } = value;

        // Find conversation and verify user is participant
        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
          return socket.emit('error', {
            event: 'send_message',
            message: 'Conversation not found',
          });
        }

        if (!conversation.isParticipant(socket.userId)) {
          return socket.emit('error', {
            event: 'send_message',
            message: 'You are not part of this conversation',
          });
        }

        // Validate receiver is the other participant
        const otherParticipant = conversation.getOtherParticipant(socket.userId);
        if (otherParticipant.toString() !== receiverId) {
          return socket.emit('error', {
            event: 'send_message',
            message: 'Invalid receiver ID',
          });
        }

        // Get receiver type from participantTypes
        const receiverType = conversation.participantTypes.find(
          (pt) => pt.userId.toString() === receiverId
        )?.userType;

        // Create message
        const message = new Message({
          conversationId,
          senderId: socket.userId,
          senderType: socket.userRole,
          receiverId,
          receiverType,
          messageType,
          content,
          metadata: metadata || {},
        });

        await message.save();

        // Update conversation last message
        conversation.updateLastMessage(message);
        conversation.incrementUnreadCount(receiverId);
        await conversation.save();

        // Get sender info
        const senderInfo = await getUserInfo(socket.userId, socket.token);

        // Format message for response
        const formattedMessage = formatMessageForResponse(message, senderInfo);

        // Emit confirmation to sender
        socket.emit('message_sent', {
          tempId, // Echo back client's temp ID for optimistic UI updates
          messageId: message._id,
          timestamp: message.createdAt,
        });

        // Emit to receiver (if online)
        if (onlineUsers.has(receiverId)) {
          io.to(receiverId).emit('new_message', formattedMessage);

          // Mark as delivered immediately
          message.markAsDelivered();
          await message.save();

          // Emit delivery confirmation to sender
          socket.emit('message_delivered', {
            messageId: message._id,
            deliveredAt: message.deliveredAt,
          });

          // Publish Kafka event
          await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_DELIVERED, {
            eventType: 'message.delivered',
            messageId: message._id.toString(),
            deliveredAt: Date.now(),
          });
        } else {
          // User offline - notification will be handled by notification service
          console.log(`User ${receiverId} is offline, notification will be sent`);
        }

        // Publish Kafka event for message sent
        await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_SENT, {
          eventType: 'message.sent',
          messageId: message._id.toString(),
          conversationId,
          senderId: socket.userId,
          receiverId,
          messageType,
          timestamp: Date.now(),
          isReceiverOnline: onlineUsers.has(receiverId),
        });
      } catch (error) {
        console.error('Error in send_message handler:', error);
        socket.emit('error', {
          event: 'send_message',
          message: 'Failed to send message',
        });
      }
    });

    // Handle typing_start event
    socket.on('typing_start', async (payload) => {
      try {
        // Validate payload
        const { error, value } = typingEventSchema.validate(payload);
        if (error) {
          return socket.emit('error', {
            event: 'typing_start',
            message: error.details[0].message,
          });
        }

        const { conversationId, receiverId } = value;

        // Verify user is participant in conversation
        const conversation = await Conversation.findById(conversationId);
        if (!conversation || !conversation.isParticipant(socket.userId)) {
          return;
        }

        // Get sender info for display
        const senderInfo = await getUserInfo(socket.userId, socket.token);

        // Emit to receiver only
        io.to(receiverId).emit('user_typing', {
          conversationId,
          userId: socket.userId,
          userName: senderInfo?.fullName || senderInfo?.name || 'User',
        });
      } catch (error) {
        console.error('Error in typing_start handler:', error);
      }
    });

    // Handle typing_stop event
    socket.on('typing_stop', async (payload) => {
      try {
        // Validate payload
        const { error, value } = typingEventSchema.validate(payload);
        if (error) {
          return;
        }

        const { conversationId, receiverId } = value;

        // Verify user is participant
        const conversation = await Conversation.findById(conversationId);
        if (!conversation || !conversation.isParticipant(socket.userId)) {
          return;
        }

        // Emit to receiver only
        io.to(receiverId).emit('user_stopped_typing', {
          conversationId,
          userId: socket.userId,
        });
      } catch (error) {
        console.error('Error in typing_stop handler:', error);
      }
    });

    // Handle mark_as_read event
    socket.on('mark_as_read', async (payload) => {
      try {
        // Validate payload
        const { error, value } = markAsReadSocketSchema.validate(payload);
        if (error) {
          return socket.emit('error', {
            event: 'mark_as_read',
            message: error.details[0].message,
          });
        }

        const { conversationId, messageIds } = value;

        // Find conversation and verify user is participant
        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
          return socket.emit('error', {
            event: 'mark_as_read',
            message: 'Conversation not found',
          });
        }

        if (!conversation.isParticipant(socket.userId)) {
          return socket.emit('error', {
            event: 'mark_as_read',
            message: 'You are not part of this conversation',
          });
        }

        // Mark messages as read
        await Message.markMultipleAsRead(messageIds, socket.userId);

        // Reset unread count for user in conversation
        conversation.resetUnreadCount(socket.userId);
        await conversation.save();

        // Get messages to find senders
        const messages = await Message.find({ _id: { $in: messageIds } });
        const senderIds = [...new Set(messages.map((msg) => msg.senderId.toString()))];

        // Emit to senders
        const readAt = new Date();
        for (const senderId of senderIds) {
          if (senderId !== socket.userId && onlineUsers.has(senderId)) {
            io.to(senderId).emit('messages_read', {
              conversationId,
              messageIds,
              readBy: socket.userId,
              readAt,
            });
          }
        }

        // Publish Kafka event
        await publishToKafka(KAFKA_TOPICS.MESSAGE.MESSAGE_READ, {
          eventType: 'message.read',
          conversationId,
          messageIds,
          readBy: socket.userId,
          readAt: Date.now(),
        });

        // Confirm to sender
        socket.emit('mark_as_read_success', {
          conversationId,
          messageIds,
        });
      } catch (error) {
        console.error('Error in mark_as_read handler:', error);
        socket.emit('error', {
          event: 'mark_as_read',
          message: 'Failed to mark messages as read',
        });
      }
    });

    // Handle join_conversation event (optional - for grouping sockets by conversation)
    socket.on('join_conversation', async (payload) => {
      try {
        const { conversationId } = payload;

        // Verify conversation exists and user is participant
        const conversation = await Conversation.findById(conversationId);
        if (conversation && conversation.isParticipant(socket.userId)) {
          socket.join(`conversation_${conversationId}`);
          console.log(`User ${socket.userId} joined conversation ${conversationId}`);
        }
      } catch (error) {
        console.error('Error in join_conversation handler:', error);
      }
    });

    // Handle disconnect event
    socket.on('disconnect', async () => {
      console.log(`❌ User disconnected: ${socket.userId}`);

      // Remove from online users map
      onlineUsers.delete(socket.userId);

      // Set user as offline in Redis
      try {
        await setUserOffline(socket.userId);
      } catch (error) {
        console.warn('Could not update Redis presence:', error.message);
      }

      // Broadcast offline status to user's contacts
      try {
        const contacts = await getContactsForUser(socket.userId);
        contacts.forEach((contactId) => {
          io.to(contactId).emit('user_offline', {
            userId: socket.userId,
            timestamp: Date.now(),
          });
        });
      } catch (error) {
        console.error('Error broadcasting offline status:', error.message);
      }
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error('Socket error:', error);
    });
  });

  return onlineUsers;
};
