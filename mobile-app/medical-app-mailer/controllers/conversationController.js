const mongoose = require("mongoose");
const {
  Conversation,
  Message,
} = require("../models/conversationModel");
const User = require("../models/userModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");
const path = require("path");

// Get all conversations for a user
exports.getConversations = catchAsync(async (req, res, next) => {
  const userId = req.user.id;
  const isDoctor = req.user.role === "medecin";

  // Query based on user role
  const query = isDoctor
    ? { doctorId: userId }
    : { patientId: userId };

  const conversations = await Conversation.find(query).sort({
    lastMessageTime: -1,
  });

  res.status(200).json({
    status: "success",
    results: conversations.length,
    data: {
      conversations,
    },
  });
});

// Get a single conversation
exports.getConversation = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const userId = req.user.id;

  const conversation = await Conversation.findById(id);

  if (!conversation) {
    return next(new AppError("Conversation non trouvée", 404));
  }

  // Check if user is part of the conversation
  if (
    conversation.patientId.toString() !== userId &&
    conversation.doctorId.toString() !== userId
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à cette conversation",
        403
      )
    );
  }

  res.status(200).json({
    status: "success",
    data: {
      conversation,
    },
  });
});

// Get messages for a conversation
exports.getMessages = catchAsync(async (req, res, next) => {
  const { conversationId } = req.params;
  const userId = req.user.id;

  // Check if conversation exists and user is part of it
  const conversation = await Conversation.findById(conversationId);

  if (!conversation) {
    return next(new AppError("Conversation non trouvée", 404));
  }

  if (
    conversation.patientId.toString() !== userId &&
    conversation.doctorId.toString() !== userId
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à cette conversation",
        403
      )
    );
  }

  // Find messages for this conversation
  const messages = await Message.find({
    conversation: conversationId,
  })
    .sort({ timestamp: -1 })
    .limit(100);

  res.status(200).json({
    status: "success",
    results: messages.length,
    data: {
      messages,
    },
  });
});

// Create or get conversation between patient and doctor
exports.createConversation = catchAsync(async (req, res, next) => {
  const { patientId, doctorId } = req.body;

  // Check if both users exist
  const patient = await User.findOne({
    _id: patientId,
    role: "patient",
  });
  if (!patient) {
    return next(new AppError("Patient non trouvé", 404));
  }

  const doctor = await User.findOne({
    _id: doctorId,
    role: "medecin",
  });
  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  // Check if current user is either the patient or the doctor
  if (req.user.id !== patientId && req.user.id !== doctorId) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à créer cette conversation",
        403
      )
    );
  }

  // Check if conversation already exists
  let conversation = await Conversation.findOne({
    patientId,
    doctorId,
  });

  if (conversation) {
    return res.status(200).json({
      status: "success",
      data: {
        conversation,
      },
    });
  }

  // Create new conversation
  conversation = await Conversation.create({
    patientId,
    doctorId,
    patientName: `${patient.name} ${patient.lastName}`,
    doctorName: `${doctor.name} ${doctor.lastName}`,
  });

  res.status(201).json({
    status: "success",
    data: {
      conversation,
    },
  });
});

// Send a message in a conversation
exports.sendMessage = catchAsync(async (req, res, next) => {
  const { conversationId } = req.params;
  const { content } = req.body;
  const senderId = req.user.id;

  // Check if conversation exists
  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    return next(new AppError("Conversation non trouvée", 404));
  }

  // Check if user is part of the conversation
  if (
    conversation.patientId.toString() !== senderId &&
    conversation.doctorId.toString() !== senderId
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à envoyer des messages dans cette conversation",
        403
      )
    );
  }

  // Determine message type and handle file if present
  let messageType = "text";
  let fileUrl = null;
  let fileName = null;
  let fileSize = null;
  let fileMimeType = null;

  if (req.file) {
    // Handle file upload
    const file = req.file;

    if (file.mimetype.startsWith("image/")) {
      messageType = "image";
    } else {
      messageType = "file";
    }

    // Create file path relative to server
    fileUrl = `/uploads/conversations/${file.filename}`;
    fileName = file.originalname;
    fileSize = file.size;
    fileMimeType = file.mimetype;
  } else if (!content) {
    return next(
      new AppError("Le message ne peut pas être vide", 400)
    );
  }

  // Create message
  const message = await Message.create({
    conversation: conversationId,
    sender: senderId,
    content: content || "",
    type: messageType,
    fileUrl,
    fileName,
    fileSize,
    fileMimeType,
    readBy: [senderId], // Sender has read their own message
    status: "sent",
  });

  // Update conversation with last message info
  await Conversation.findByIdAndUpdate(conversationId, {
    lastMessage:
      content || (messageType === "image" ? "Image" : "Fichier"),
    lastMessageType: messageType,
    lastMessageTime: new Date(),
    lastMessageSenderId: senderId,
    lastMessageReadBy: [senderId],
    lastMessageUrl: fileUrl,
  });

  res.status(201).json({
    status: "success",
    data: {
      message,
    },
  });
});

// Store message (used by socket.io)
exports.storeMessage = catchAsync(async (req, res, next) => {
  const { conversationId, content, type } = req.body;
  const senderId = req.user.id;

  // Check if conversation exists
  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    return next(new AppError("Conversation non trouvée", 404));
  }

  // Determine recipient ID
  const recipientId =
    conversation.patientId.toString() === senderId
      ? conversation.doctorId.toString()
      : conversation.patientId.toString();

  // Check if user is part of the conversation
  if (
    conversation.patientId.toString() !== senderId &&
    conversation.doctorId.toString() !== senderId
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à envoyer des messages dans cette conversation",
        403
      )
    );
  }

  // Handle file if present
  let messageType = type || "text";
  let fileUrl = req.body.fileUrl || null;
  let fileName = req.body.fileName || null;
  let fileSize = req.body.fileSize || null;
  let fileMimeType = req.body.fileMimeType || null;

  if (messageType !== "text" && !fileUrl) {
    return next(
      new AppError(
        "URL du fichier manquante pour un message de type fichier ou image",
        400
      )
    );
  }

  if (messageType === "text" && !content) {
    return next(
      new AppError("Le contenu du message ne peut pas être vide", 400)
    );
  }

  // Create message
  const message = await Message.create({
    conversation: conversationId,
    sender: senderId,
    content: content || "",
    type: messageType,
    fileUrl,
    fileName,
    fileSize,
    fileMimeType,
    readBy: [senderId],
    status: "sent",
  });

  // Update conversation with last message info
  await Conversation.findByIdAndUpdate(conversationId, {
    lastMessage:
      content || (messageType === "image" ? "Image" : "Fichier"),
    lastMessageType: messageType,
    lastMessageTime: new Date(),
    lastMessageSenderId: senderId,
    lastMessageReadBy: [senderId],
    lastMessageUrl: fileUrl,
  });

  res.status(201).json({
    status: "success",
    data: {
      message,
      recipientId,
    },
  });
});

// Mark messages as read
exports.markAsRead = catchAsync(async (req, res, next) => {
  const { conversationId } = req.params;
  const userId = req.user.id;

  // Check if conversation exists
  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    return next(new AppError("Conversation non trouvée", 404));
  }

  // Check if user is part of the conversation
  if (
    conversation.patientId.toString() !== userId &&
    conversation.doctorId.toString() !== userId
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à cette conversation",
        403
      )
    );
  }

  // Update all unread messages sent by the other user
  const otherUserId =
    conversation.patientId.toString() === userId
      ? conversation.doctorId
      : conversation.patientId;

  await Message.updateMany(
    {
      conversation: conversationId,
      sender: otherUserId,
      readBy: { $ne: userId },
    },
    {
      $addToSet: { readBy: userId },
      status: "read",
    }
  );

  // Update conversation's last message read status if needed
  if (
    conversation.lastMessageSenderId &&
    conversation.lastMessageSenderId.toString() ===
      otherUserId.toString()
  ) {
    await Conversation.findByIdAndUpdate(conversationId, {
      $addToSet: { lastMessageReadBy: userId },
    });
  }

  res.status(200).json({
    status: "success",
    message: "Messages marqués comme lus",
  });
});

// Helper method for marking messages as read via Socket.IO
exports.markMessagesAsRead = async (userId, conversationId) => {
  try {
    // Check if conversation exists
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      console.error("Conversation not found:", conversationId);
      return false;
    }

    // Check if user is part of the conversation
    if (
      conversation.patientId.toString() !== userId &&
      conversation.doctorId.toString() !== userId
    ) {
      console.error(
        "User not authorized for this conversation:",
        userId
      );
      return false;
    }

    // Update all unread messages sent by the other user
    const otherUserId =
      conversation.patientId.toString() === userId
        ? conversation.doctorId
        : conversation.patientId;

    await Message.updateMany(
      {
        conversation: conversationId,
        sender: otherUserId,
        readBy: { $ne: userId },
      },
      {
        $addToSet: { readBy: userId },
        status: "read",
      }
    );

    // Update conversation's last message read status if needed
    if (
      conversation.lastMessageSenderId &&
      conversation.lastMessageSenderId.toString() ===
        otherUserId.toString()
    ) {
      await Conversation.findByIdAndUpdate(conversationId, {
        $addToSet: { lastMessageReadBy: userId },
      });
    }

    return true;
  } catch (error) {
    console.error("Error marking messages as read:", error);
    return false;
  }
};
