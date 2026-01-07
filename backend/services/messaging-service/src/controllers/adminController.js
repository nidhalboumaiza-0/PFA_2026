import Message from '../models/Message.js';
import Conversation from '../models/Conversation.js';
import { mongoose } from '../../../../shared/index.js';

/**
 * Get messaging statistics for admin dashboard
 * GET /api/v1/messaging/admin/stats
 */
export const getMessagingStats = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalConversations,
      activeConversations,
      totalMessages,
      messagesToday,
      messagesThisWeek,
      messagesThisMonth,
      textMessages,
      imageMessages,
      documentMessages
    ] = await Promise.all([
      Conversation.countDocuments(),
      Conversation.countDocuments({ isActive: true, isArchived: false }),
      Message.countDocuments({ isDeleted: { $ne: true } }),
      Message.countDocuments({ createdAt: { $gte: today }, isDeleted: { $ne: true } }),
      Message.countDocuments({ createdAt: { $gte: thisWeek }, isDeleted: { $ne: true } }),
      Message.countDocuments({ createdAt: { $gte: thisMonth }, isDeleted: { $ne: true } }),
      Message.countDocuments({ messageType: 'text', isDeleted: { $ne: true } }),
      Message.countDocuments({ messageType: 'image', isDeleted: { $ne: true } }),
      Message.countDocuments({ messageType: 'document', isDeleted: { $ne: true } })
    ]);

    // Get message trend (last 30 days)
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    
    const messageTrend = await Message.aggregate([
      {
        $match: {
          createdAt: { $gte: thirtyDaysAgo },
          isDeleted: { $ne: true }
        }
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Get conversation type distribution
    const conversationTypeDistribution = await Conversation.aggregate([
      {
        $group: {
          _id: '$conversationType',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get busiest hours for messaging
    const busiestHours = await Message.aggregate([
      {
        $match: { isDeleted: { $ne: true } }
      },
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Calculate read rate
    const totalNonSystemMessages = await Message.countDocuments({
      messageType: { $ne: 'system' },
      isDeleted: { $ne: true }
    });
    const readMessages = await Message.countDocuments({
      isRead: true,
      messageType: { $ne: 'system' },
      isDeleted: { $ne: true }
    });
    const readRate = totalNonSystemMessages > 0 
      ? ((readMessages / totalNonSystemMessages) * 100).toFixed(1)
      : '0';

    const stats = {
      overview: {
        totalConversations,
        activeConversations,
        archivedConversations: totalConversations - activeConversations,
        totalMessages,
        readRate
      },
      period: {
        today: messagesToday,
        thisWeek: messagesThisWeek,
        thisMonth: messagesThisMonth
      },
      messageTypes: {
        text: textMessages,
        image: imageMessages,
        document: documentMessages
      },
      conversationTypes: conversationTypeDistribution.map(ct => ({
        type: ct._id,
        count: ct.count
      })),
      messageTrend,
      busiestHours: busiestHours.map(h => ({
        hour: `${h._id.toString().padStart(2, '0')}:00`,
        count: h.count
      })),
      generatedAt: new Date().toISOString()
    };

    res.json(stats);

  } catch (error) {
    console.error('[AdminMessagingController.getMessagingStats] Error:', error);
    res.status(500).json({ message: 'Failed to fetch messaging stats', error: error.message });
  }
};

/**
 * Get recent messaging activity
 * GET /api/v1/messaging/admin/recent-activity
 */
export const getRecentActivity = async (req, res) => {
  try {
    const { limit = 20 } = req.query;

    const recentConversations = await Conversation.find()
      .sort({ 'lastMessage.timestamp': -1 })
      .limit(parseInt(limit))
      .lean();

    res.json({
      recentActivity: recentConversations,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[AdminMessagingController.getRecentActivity] Error:', error);
    res.status(500).json({ message: 'Failed to fetch recent activity', error: error.message });
  }
};

/**
 * Get all conversations with filters (admin oversight)
 * GET /api/v1/messaging/admin/conversations
 */
export const getAllConversations = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      isActive,
      conversationType,
      sortBy = 'lastMessage.timestamp',
      sortOrder = 'desc'
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const query = {};
    
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    
    if (conversationType) {
      query.conversationType = conversationType;
    }

    const [conversations, total] = await Promise.all([
      Conversation.find(query)
        .sort(sortOptions)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Conversation.countDocuments(query)
    ]);

    res.json({
      conversations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('[AdminMessagingController.getAllConversations] Error:', error);
    res.status(500).json({ message: 'Failed to fetch conversations', error: error.message });
  }
};
