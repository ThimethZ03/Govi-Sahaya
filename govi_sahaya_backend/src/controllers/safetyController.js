const Message = require('../models/Message');
const User = require('../models/User');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Send message
// @route   POST /api/safety/messages
// @access  Private
exports.sendMessage = async (req, res) => {
  try {
    const { receiverId, content, messageType, attachment } = req.body;

    // Check if receiver exists
    const receiver = await User.findById(receiverId);

    if (!receiver) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Receiver not found',
      });
    }

    const message = await Message.create({
      sender: req.user.id,
      receiver: receiverId,
      content,
      messageType: messageType || 'text',
      attachment,
    });

    await message.populate([
      { path: 'sender', select: 'name profilePicture' },
      { path: 'receiver', select: 'name profilePicture' },
    ]);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Message sent successfully',
      data: message,
    });
  } catch (error) {
    logger.error('Send message error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Get conversations (list of users you've messaged with)
// @route   GET /api/safety/conversations
// @access  Private
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get all unique users the current user has messaged with
    const sentTo = await Message.distinct('receiver', { sender: userId });
    const receivedFrom = await Message.distinct('sender', { receiver: userId });

    // Combine and get unique user IDs
    const userIds = [...new Set([...sentTo, ...receivedFrom])];

    // Get user details and last message
    const conversations = await Promise.all(
      userIds.map(async (otherUserId) => {
        const user = await User.findById(otherUserId).select('name profilePicture role');

        // Get last message
        const lastMessage = await Message.findOne({
          $or: [
            { sender: userId, receiver: otherUserId },
            { sender: otherUserId, receiver: userId },
          ],
        })
          .sort({ createdAt: -1 })
          .limit(1);

        // Count unread messages
        const unreadCount = await Message.countDocuments({
          sender: otherUserId,
          receiver: userId,
          isRead: false,
        });

        return {
          user,
          lastMessage,
          unreadCount,
        };
      })
    );

    // Sort by last message timestamp
    conversations.sort((a, b) => {
      const dateA = a.lastMessage?.createdAt || 0;
      const dateB = b.lastMessage?.createdAt || 0;
      return dateB - dateA;
    });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    logger.error('Get conversations error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch conversations',
    });
  }
};

// @desc    Get messages with a specific user
// @route   GET /api/safety/messages/:userId
// @access  Private
exports.getMessages = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const otherUserId = req.params.userId;

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const messages = await Message.find({
      $or: [
        { sender: currentUserId, receiver: otherUserId },
        { sender: otherUserId, receiver: currentUserId },
      ],
      isDeleted: false,
    })
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip)
      .populate('sender', 'name profilePicture')
      .populate('receiver', 'name profilePicture');

    const total = await Message.countDocuments({
      $or: [
        { sender: currentUserId, receiver: otherUserId },
        { sender: otherUserId, receiver: currentUserId },
      ],
      isDeleted: false,
    });

    // Mark messages as read
    await Message.updateMany(
      {
        sender: otherUserId,
        receiver: currentUserId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: Date.now(),
      }
    );

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: messages.reverse(), // Reverse to show oldest first
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get messages error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch messages',
    });
  }
};

// @desc    Mark message as read
// @route   PUT /api/safety/messages/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const message = await Message.findById(req.params.id);

    if (!message) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Message not found',
      });
    }

    // Check if user is the receiver
    if (message.receiver.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to mark this message as read',
      });
    }

    message.isRead = true;
    message.readAt = Date.now();
    await message.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Message marked as read',
      data: message,
    });
  } catch (error) {
    logger.error('Mark as read error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to mark message as read',
    });
  }
};

// @desc    Delete message
// @route   DELETE /api/safety/messages/:id
// @access  Private
exports.deleteMessage = async (req, res) => {
  try {
    const message = await Message.findById(req.params.id);

    if (!message) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Message not found',
      });
    }

    // Check if user is sender or receiver
    const userId = req.user.id;
    if (
      message.sender.toString() !== userId &&
      message.receiver.toString() !== userId
    ) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this message',
      });
    }

    message.isDeleted = true;
    message.deletedBy = userId;
    await message.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Message deleted successfully',
    });
  } catch (error) {
    logger.error('Delete message error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete message',
    });
  }
};

// @desc    Get unread messages count
// @route   GET /api/safety/messages/unread/count
// @access  Private
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Message.countDocuments({
      receiver: req.user.id,
      isRead: false,
      isDeleted: false,
    });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: { count },
    });
  } catch (error) {
    logger.error('Get unread count error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch unread count',
    });
  }
};

// @desc    Search users for messaging
// @route   GET /api/safety/users/search
// @access  Private
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const users = await User.find({
      _id: { $ne: req.user.id }, // Exclude current user
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
      isActive: true,
    })
      .select('name email profilePicture role location')
      .limit(20);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: users,
    });
  } catch (error) {
    logger.error('Search users error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Search failed',
    });
  }
};

// @desc    Get expert users
// @route   GET /api/safety/experts
// @access  Private
exports.getExperts = async (req, res) => {
  try {
    const experts = await User.find({
      role: 'expert',
      isActive: true,
      isVerified: true,
    })
      .select('name email phone profilePicture location')
      .limit(20);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: experts,
      count: experts.length,
    });
  } catch (error) {
    logger.error('Get experts error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch experts',
    });
  }
};

// @desc    Block user
// @route   POST /api/safety/block/:userId
// @access  Private
exports.blockUser = async (req, res) => {
  try {
    // This is a placeholder for block functionality
    // You would need to add a 'blockedUsers' array to User model
    const userToBlock = await User.findById(req.params.userId);

    if (!userToBlock) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    // TODO: Implement block logic in User model

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'User blocked successfully',
    });
  } catch (error) {
    logger.error('Block user error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to block user',
    });
  }
};

// @desc    Report user/message
// @route   POST /api/safety/report
// @access  Private
exports.reportUser = async (req, res) => {
  try {
    const { userId, messageId, reason, description } = req.body;

    // TODO: Create a Report model and save report
    // This is a placeholder implementation

    logger.info('Report submitted:', {
      reporter: req.user.id,
      userId,
      messageId,
      reason,
    });

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Report submitted successfully. Our team will review it.',
    });
  } catch (error) {
    logger.error('Report user error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to submit report',
    });
  }
};
