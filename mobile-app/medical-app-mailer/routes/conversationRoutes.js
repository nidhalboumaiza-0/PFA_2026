const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const conversationController = require("../controllers/conversationController");
const uploadUtils = require("../utils/upload");

// All routes are protected
router.use(authController.protect);

// Conversation routes
router.post("/", conversationController.createConversation);
router.get("/", conversationController.getConversations);
router.get("/:id", conversationController.getConversation);
router.get(
  "/:conversationId/messages",
  conversationController.getMessages
);

// Message routes with file upload
router.post(
  "/:conversationId/messages",
  uploadUtils.uploadConversationFile,
  conversationController.sendMessage
);

// Store message from socket.io
router.post(
  "/:conversationId/store-message",
  conversationController.storeMessage
);

// Mark messages as read
router.patch(
  "/:conversationId/read",
  conversationController.markAsRead
);

module.exports = router;
