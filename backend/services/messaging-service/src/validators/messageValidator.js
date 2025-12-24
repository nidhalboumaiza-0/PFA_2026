import Joi from 'joi';

// Validation schema for creating/getting a conversation
export const createConversationSchema = Joi.object({
  recipientId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid recipient ID format',
      'any.required': 'Recipient ID is required',
    }),
  recipientType: Joi.string()
    .valid('patient', 'doctor')
    .required()
    .messages({
      'any.only': 'Recipient type must be either patient or doctor',
      'any.required': 'Recipient type is required',
    }),
});

// Validation schema for getting conversations list
export const getConversationsSchema = Joi.object({
  type: Joi.string()
    .valid('all', 'patient_doctor', 'doctor_doctor')
    .default('all'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

// Validation schema for getting conversation messages
export const getMessagesSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(50),
  before: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
});

// Validation schema for marking messages as read
export const markAsReadSchema = Joi.object({
  messageIds: Joi.array()
    .items(Joi.string().pattern(/^[0-9a-fA-F]{24}$/))
    .min(1)
    .required()
    .messages({
      'array.min': 'At least one message ID is required',
      'any.required': 'Message IDs are required',
    }),
});

// Validation schema for sending file attachment
export const sendFileSchema = Joi.object({
  receiverId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid receiver ID format',
      'any.required': 'Receiver ID is required',
    }),
  messageType: Joi.string()
    .valid('image', 'document')
    .required()
    .messages({
      'any.only': 'Message type must be either image or document',
      'any.required': 'Message type is required',
    }),
  caption: Joi.string().max(500).allow('', null),
});

// Validation schema for searching messages
export const searchMessagesSchema = Joi.object({
  query: Joi.string()
    .min(1)
    .max(200)
    .required()
    .messages({
      'string.min': 'Search query must be at least 1 character',
      'any.required': 'Search query is required',
    }),
  conversationId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20),
});

// Validation schema for Socket.IO send_message event
export const sendMessageSocketSchema = Joi.object({
  conversationId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid conversation ID format',
      'any.required': 'Conversation ID is required',
    }),
  receiverId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid receiver ID format',
      'any.required': 'Receiver ID is required',
    }),
  messageType: Joi.string()
    .valid('text', 'system')
    .default('text'),
  content: Joi.string()
    .min(1)
    .max(5000)
    .required()
    .messages({
      'string.min': 'Message content cannot be empty',
      'string.max': 'Message content cannot exceed 5000 characters',
      'any.required': 'Message content is required',
    }),
  tempId: Joi.string().allow('', null), // Client-side temporary ID
  metadata: Joi.object().allow(null),
});

// Validation schema for Socket.IO typing events
export const typingEventSchema = Joi.object({
  conversationId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid conversation ID format',
      'any.required': 'Conversation ID is required',
    }),
  receiverId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid receiver ID format',
      'any.required': 'Receiver ID is required',
    }),
});

// Validation schema for Socket.IO mark_as_read event
export const markAsReadSocketSchema = Joi.object({
  conversationId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid conversation ID format',
      'any.required': 'Conversation ID is required',
    }),
  messageIds: Joi.array()
    .items(Joi.string().pattern(/^[0-9a-fA-F]{24}$/))
    .min(1)
    .required()
    .messages({
      'array.min': 'At least one message ID is required',
      'any.required': 'Message IDs are required',
    }),
});

// Middleware to validate request body
export const validateCreateConversation = (req, res, next) => {
  const { error } = createConversationSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  next();
};

export const validateGetConversations = (req, res, next) => {
  const { error, value } = getConversationsSchema.validate(req.query);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  req.query = value;
  next();
};

export const validateGetMessages = (req, res, next) => {
  const { error, value } = getMessagesSchema.validate(req.query);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  req.query = value;
  next();
};

export const validateMarkAsRead = (req, res, next) => {
  const { error } = markAsReadSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  next();
};

export const validateSendFile = (req, res, next) => {
  const { error } = sendFileSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  next();
};

export const validateSearchMessages = (req, res, next) => {
  const { error, value } = searchMessagesSchema.validate(req.query);
  if (error) {
    return res.status(400).json({ message: error.details[0].message });
  }
  req.query = value;
  next();
};
