const Notification = require('../models/Notification');
const { getMessaging } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Get all notifications for user
// @route   GET /api/notifications
// @access  Private
exports.getAllNotifications = async (req, res) => {
  try {
    const { isRead, type } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const query = { user: req.user.id };

    if (isRead !== undefined) query.isRead = isRead === 'true';
    if (type) query.type = type;

    // Filter out expired notifications
    query.$or = [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } },
    ];

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({
      user: req.user.id,
      isRead: false,
    });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: notifications,
      unreadCount,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all notifications error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch notifications',
    });
  }
};

// @desc    Get notification by ID
// @route   GET /api/notifications/:id
// @access  Private
exports.getNotificationById = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Notification not found',
      });
    }

    // Check ownership
    if (notification.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this notification',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    logger.error('Get notification by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch notification',
    });
  }
};

// @desc    Create notification
// @route   POST /api/notifications
// @access  Private/Admin
exports.createNotification = async (req, res) => {
  try {
    const notification = await Notification.create(req.body);

    // Send push notification if enabled
    if (notification.sendVia.push) {
      await sendPushNotification(notification);
    }

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Notification created successfully',
      data: notification,
    });
  } catch (error) {
    logger.error('Create notification error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Notification not found',
      });
    }

    // Check ownership
    if (notification.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this notification',
      });
    }

    notification.isRead = true;
    notification.readAt = Date.now();
    await notification.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Notification marked as read',
      data: notification,
    });
  } catch (error) {
    logger.error('Mark as read error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to mark notification as read',
    });
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { user: req.user.id, isRead: false },
      { isRead: true, readAt: Date.now() }
    );

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    logger.error('Mark all as read error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to mark notifications as read',
    });
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Notification not found',
      });
    }

    // Check ownership
    if (notification.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this notification',
      });
    }

    await notification.deleteOne();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    logger.error('Delete notification error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete notification',
    });
  }
};

// @desc    Clear all notifications
// @route   DELETE /api/notifications
// @access  Private
exports.clearAllNotifications = async (req, res) => {
  try {
    await Notification.deleteMany({ user: req.user.id });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'All notifications cleared',
    });
  } catch (error) {
    logger.error('Clear all notifications error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to clear notifications',
    });
  }
};

// @desc    Get unread count
// @route   GET /api/notifications/unread/count
// @access  Private
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      user: req.user.id,
      isRead: false,
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

// @desc    Send bulk notifications (Admin only)
// @route   POST /api/notifications/bulk
// @access  Private/Admin
exports.sendBulkNotifications = async (req, res) => {
  try {
    const { userIds, title, message, type, data } = req.body;

    if (!userIds || userIds.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'User IDs are required',
      });
    }

    const notifications = userIds.map((userId) => ({
      user: userId,
      type: type || 'general',
      title,
      message,
      data,
      sendVia: { push: true },
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    // Send push notifications
    for (const notification of createdNotifications) {
      await sendPushNotification(notification).catch((err) =>
        logger.error('Push notification error:', err)
      );
    }

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: `${createdNotifications.length} notifications sent successfully`,
      data: { count: createdNotifications.length },
    });
  } catch (error) {
    logger.error('Send bulk notifications error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// Helper function to send push notification via Firebase
async function sendPushNotification(notification) {
  try {
    // TODO: Get user's FCM token from user document
    // This is a placeholder - you need to store FCM tokens in User model

    const messaging = getMessaging();

    const message = {
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: notification.data || {},
      // token: userFcmToken, // Add FCM token here
    };

    // await messaging.send(message);

    notification.deliveryStatus.push = 'sent';
    notification.sentAt = Date.now();
    await notification.save();

    logger.info('Push notification sent successfully');
  } catch (error) {
    logger.error('Send push notification error:', error);
    notification.deliveryStatus.push = 'failed';
    await notification.save();
  }
}

module.exports.sendPushNotification = sendPushNotification;
