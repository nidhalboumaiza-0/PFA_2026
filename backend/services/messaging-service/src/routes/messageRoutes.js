import express from 'express';
import { auth } from '../../../../shared/index.js';
import { uploadMessageFile } from '../config/multerMessage.js';
import {
  createOrGetConversation,
  getUserConversations,
  getConversationMessages,
  markMessagesAsRead,
  sendFileMessage,
  deleteMessage,
  getUnreadCount,
  searchMessages,
  getOnlineStatus,
} from '../controllers/messageController.js';
import {
  validateCreateConversation,
  validateGetConversations,
  validateGetMessages,
  validateMarkAsRead,
  validateSendFile,
  validateSearchMessages,
} from '../validators/messageValidator.js';

const router = express.Router();

/**
 * @route   POST /api/v1/messages/conversations
 * @desc    Create or get existing conversation
 * @access  Private (any authenticated user)
 */
router.post('/conversations', auth, validateCreateConversation, createOrGetConversation);

/**
 * @route   GET /api/v1/messages/conversations
 * @desc    Get user's conversations list
 * @access  Private (any authenticated user)
 */
router.get('/conversations', auth, validateGetConversations, getUserConversations);

/**
 * @route   GET /api/v1/messages/conversations/:conversationId/messages
 * @desc    Get conversation messages (history)
 * @access  Private (conversation participant)
 */
router.get(
  '/conversations/:conversationId/messages',
  auth,
  validateGetMessages,
  getConversationMessages
);

/**
 * @route   PUT /api/v1/messages/conversations/:conversationId/mark-read
 * @desc    Mark messages as read
 * @access  Private (conversation participant)
 */
router.put(
  '/conversations/:conversationId/mark-read',
  auth,
  validateMarkAsRead,
  markMessagesAsRead
);

/**
 * @route   POST /api/v1/messages/conversations/:conversationId/send-file
 * @desc    Send message with file attachment
 * @access  Private (conversation participant)
 */
router.post(
  '/conversations/:conversationId/send-file',
  auth,
  uploadMessageFile.single('file'),
  validateSendFile,
  sendFileMessage
);

/**
 * @route   DELETE /api/v1/messages/:messageId
 * @desc    Delete message (soft delete)
 * @access  Private (message sender only)
 */
router.delete('/:messageId', auth, deleteMessage);

/**
 * @route   GET /api/v1/messages/unread-count
 * @desc    Get unread message count for user
 * @access  Private (any authenticated user)
 */
router.get('/unread-count', auth, getUnreadCount);

/**
 * @route   GET /api/v1/messages/search
 * @desc    Search messages by content
 * @access  Private (any authenticated user)
 */
router.get('/search', auth, validateSearchMessages, searchMessages);

/**
 * @route   GET /api/v1/messages/users/:userId/online-status
 * @desc    Check if user is online
 * @access  Private (any authenticated user)
 */
router.get('/users/:userId/online-status', auth, getOnlineStatus);

export default router;
