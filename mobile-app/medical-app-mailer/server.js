const app = require("./app");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const socketIo = require("socket.io");
const conversationController = require("./controllers/conversationController");

process.on("uncaughtException", (err) => {
  console.log("UNCAUGHT EXCEPTION! 💥 Shutting down...");
  console.log(err.name, err.message);
  process.exit(1);
});

// Load environment variables
dotenv.config({ path: "./.env" });

// Set NODE_ENV to development if not already set
if (!process.env.NODE_ENV) {
  process.env.NODE_ENV = "development";
  console.log(
    "Environment not specified, defaulting to development mode"
  );
}

console.log(`Running in ${process.env.NODE_ENV} mode`);

const DB = process.env.DATABASE;
mongoose.set("strictQuery", true);

mongoose
  .connect(DB, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("DB connection successful!"));

// Add a test route to app.js exports
app.get("/api/v1/test", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "Server is running correctly",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
  console.log("\n===========================================");
  console.log("🚀 Medical App Server running on port " + port);
  console.log("===========================================");
  console.log("\n📌 Available endpoints:");
  console.log("- GET  /api/v1/test - Test server connection");
  console.log("- GET  /api/v1/users - User routes");
  console.log("- GET  /api/v1/appointments - Appointment routes");
  console.log("- GET  /api/v1/conversations - Conversation routes");
  console.log("- GET  /api/v1/notifications - Notification routes");
  console.log("- GET  /api/v1/prescriptions - Prescription routes");
  console.log("===========================================\n");
});

process.on("unhandledRejection", (err) => {
  console.log("UNHANDLED REJECTION! 💥 Shutting down...");
  console.log(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});

// Initialize Socket.IO
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// Socket.IO authentication middleware
io.use((socket, next) => {
  const token = socket.handshake.auth.token;

  if (!token) {
    return next(new Error("Authentication error: Token missing"));
  }

  try {
    // Verify token (simplified - in production should use JWT verify)
    // This is a placeholder for actual token verification
    // In a real implementation, you would verify the JWT token here
    // and extract the user ID from it

    // For now, we'll assume the token is valid and the userId is provided in the query
    const userId = socket.handshake.query.userId;

    if (!userId) {
      return next(new Error("Authentication error: User ID missing"));
    }

    socket.user = { id: userId };
    next();
  } catch (error) {
    return next(new Error("Authentication error: Invalid token"));
  }
});

// Store connected users
let connectedUsers = {};
// Store users who are currently typing
let typingUsers = {};

// Socket.IO connection handling
io.on("connection", (socket) => {
  console.log("A user connected");

  // When a user connects, store their user ID and socket ID
  socket.on("userConnected", (userId) => {
    connectedUsers[userId] = socket.id;
    console.log(`User ${userId} connected with socket ${socket.id}`);
  });

  // Handle sending messages
  socket.on("sendMessage", async (data) => {
    try {
      const {
        recipientId,
        message,
        conversationId,
        type,
        fileUrl,
        fileName,
        fileSize,
        fileMimeType,
      } = data;
      const senderId = socket.handshake.query.userId;

      if (!senderId || !recipientId || !conversationId) {
        console.error("Missing data for sending message");
        return;
      }

      if (!message && type === "text") {
        console.error("Text message cannot be empty");
        return;
      }

      // Create message data object
      const messageData = {
        conversationId,
        content: message || "",
        type: type || "text",
        fileUrl,
        fileName,
        fileSize,
        fileMimeType,
      };

      // Save message to database using API endpoint
      try {
        const response = await fetch(
          `${
            process.env.BASE_URL || "http://localhost:" + port
          }/api/v1/conversations/${conversationId}/store-message`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${socket.handshake.auth.token}`,
            },
            body: JSON.stringify(messageData),
          }
        );

        if (!response.ok) {
          throw new Error(
            `Failed to store message: ${response.statusText}`
          );
        }
      } catch (error) {
        console.error("Error storing message:", error);
        return;
      }

      // Send message to recipient if they are online
      const recipientSocketId = connectedUsers[recipientId];
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("receiveMessage", {
          senderId,
          ...messageData,
          timestamp: new Date(),
        });
      }

      // Clear typing indicator when message is sent
      if (
        typingUsers[senderId] &&
        typingUsers[senderId][conversationId]
      ) {
        delete typingUsers[senderId][conversationId];

        // Notify recipient that sender stopped typing
        if (recipientSocketId) {
          io.to(recipientSocketId).emit("userStoppedTyping", {
            userId: senderId,
            conversationId,
          });
        }
      }
    } catch (error) {
      console.error("Error sending message:", error);
    }
  });

  // Handle typing indicators
  socket.on("startTyping", (data) => {
    const { conversationId, recipientId } = data;
    const userId = socket.handshake.query.userId;

    if (!userId || !conversationId || !recipientId) {
      console.error("Missing data for typing indicator");
      return;
    }

    // Initialize typing status for this user if it doesn't exist
    if (!typingUsers[userId]) {
      typingUsers[userId] = {};
    }

    // Set typing status for this conversation
    typingUsers[userId][conversationId] = true;

    // Notify recipient that user is typing
    const recipientSocketId = connectedUsers[recipientId];
    if (recipientSocketId) {
      io.to(recipientSocketId).emit("userTyping", {
        userId,
        conversationId,
      });
    }
  });

  socket.on("stopTyping", (data) => {
    const { conversationId, recipientId } = data;
    const userId = socket.handshake.query.userId;

    if (!userId || !conversationId || !recipientId) {
      console.error("Missing data for typing indicator");
      return;
    }

    // Clear typing status
    if (typingUsers[userId] && typingUsers[userId][conversationId]) {
      delete typingUsers[userId][conversationId];
    }

    // Notify recipient that user stopped typing
    const recipientSocketId = connectedUsers[recipientId];
    if (recipientSocketId) {
      io.to(recipientSocketId).emit("userStoppedTyping", {
        userId,
        conversationId,
      });
    }
  });

  // Handle read receipts
  socket.on("markMessagesAsRead", async (data) => {
    const { conversationId, senderId } = data;
    const userId = socket.handshake.query.userId;

    if (!userId || !conversationId) {
      console.error("Missing data for marking messages as read");
      return;
    }

    try {
      // Update messages in database
      await conversationController.markMessagesAsRead(
        userId,
        conversationId
      );

      // Notify message sender that their messages were read
      if (senderId) {
        const senderSocketId = connectedUsers[senderId];
        if (senderSocketId) {
          io.to(senderSocketId).emit("messagesRead", {
            userId,
            conversationId,
          });
        }
      }
    } catch (error) {
      console.error("Error marking messages as read:", error);
    }
  });

  // Handle user disconnect
  socket.on("disconnect", () => {
    console.log("A user disconnected");

    // Remove user from connected users
    for (const userId in connectedUsers) {
      if (connectedUsers[userId] === socket.id) {
        delete connectedUsers[userId];

        // Also clear typing status
        if (typingUsers[userId]) {
          delete typingUsers[userId];
        }

        console.log(`User ${userId} disconnected`);
        break;
      }
    }
  });
});
