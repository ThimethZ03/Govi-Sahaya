const Notification = require('../models/Notification');
const User = require('../models/User');
const { getMessaging } = require('../config/firebase');
const emailService = require('./emailService');
const smsService = require('./smsService');
const logger = require('../utils/logger');

// Create notification
exports.createNotification = async (userId, notificationData) => {
  try {
    const notification = await Notification.create({
      user: userId,
      ...notificationData,
    });

    // Send notification via enabled channels
    await this.deliverNotification(notification);

    return notification;
  } catch (error) {
    logger.error('Create notification error:', error);
    throw error;
  }
};

// Deliver notification via all enabled channels
exports.deliverNotification = async (notification) => {
  try {
    const user = await User.findById(notification.user);

    if (!user) {
      throw new Error('User not found');
    }

    const deliveryPromises = [];

    // Send push notification
    if (notification.sendVia.push) {
      deliveryPromises.push(
        this.sendPushNotification(user, notification)
          .then(() => {
            notification.deliveryStatus.push = 'sent';
          })
          .catch((err) => {
            logger.error('Push notification failed:', err);
            notification.deliveryStatus.push = 'failed';
          })
      );
    }

    // Send email notification
    if (notification.sendVia.email) {
      deliveryPromises.push(
        emailService
          .sendNotificationEmail(user, notification)
          .then(() => {
            notification.deliveryStatus.email = 'sent';
          })
          .catch((err) => {
            logger.error('Email notification failed:', err);
            notification.deliveryStatus.email = 'failed';
          })
      );
    }

    // Send SMS notification
    if (notification.sendVia.sms) {
      deliveryPromises.push(
        smsService
          .sendSMS(user.phone, notification.message)
          .then(() => {
            notification.deliveryStatus.sms = 'sent';
          })
          .catch((err) => {
            logger.error('SMS notification failed:', err);
            notification.deliveryStatus.sms = 'failed';
          })
      );
    }

    await Promise.all(deliveryPromises);

    notification.sentAt = Date.now();
    await notification.save();

    logger.info('Notification delivered:', notification._id);
  } catch (error) {
    logger.error('Deliver notification error:', error);
    throw error;
  }
};

// Send push notification via Firebase
exports.sendPushNotification = async (user, notification) => {
  try {
    // Get user's FCM token (you need to store this in User model)
    const fcmToken = user.fcmToken;

    if (!fcmToken) {
      logger.warn('User does not have FCM token:', user._id);
      return;
    }

    const messaging = getMessaging();

    const message = {
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: {
        notificationId: notification._id.toString(),
        type: notification.type,
        ...notification.data,
      },
      token: fcmToken,
      android: {
        priority: notification.priority === 'urgent' ? 'high' : 'normal',
        notification: {
          icon: notification.icon || 'ic_notification',
          color: '#4CAF50',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.message,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(message);
    logger.info('Push notification sent successfully:', response);

    return response;
  } catch (error) {
    logger.error('Send push notification error:', error);
    throw error;
  }
};

// Send bulk notifications
exports.sendBulkNotifications = async (userIds, notificationData) => {
  try {
    const notifications = userIds.map((userId) => ({
      user: userId,
      ...notificationData,
    }));

    const created = await Notification.insertMany(notifications);

    // Deliver all notifications
    const deliveryPromises = created.map((notification) =>
      this.deliverNotification(notification).catch((err) => {
        logger.error(`Failed to deliver notification ${notification._id}:`, err);
      })
    );

    await Promise.allSettled(deliveryPromises);

    logger.info(`Bulk notifications sent: ${created.length} notifications`);

    return {
      success: true,
      count: created.length,
    };
  } catch (error) {
    logger.error('Send bulk notifications error:', error);
    throw error;
  }
};

// Send notification to all users with specific role
exports.sendNotificationByRole = async (role, notificationData) => {
  try {
    const users = await User.find({ role, isActive: true }).select('_id');
    const userIds = users.map((user) => user._id);

    return await this.sendBulkNotifications(userIds, notificationData);
  } catch (error) {
    logger.error('Send notification by role error:', error);
    throw error;
  }
};

// Send weather alert notification
exports.sendWeatherAlert = async (location, alertData) => {
  try {
    // Find users in the affected location
    const users = await User.find({
      'location.district': location.district,
      isActive: true,
    }).select('_id');

    const userIds = users.map((user) => user._id);

    const notificationData = {
      type: 'weather_alert',
      title: `Weather Alert: ${alertData.title}`,
      message: alertData.description,
      priority: alertData.severity === 'extreme' ? 'urgent' : 'high',
      data: alertData,
      sendVia: {
        push: true,
        email: false,
        sms: alertData.severity === 'extreme',
      },
    };

    return await this.sendBulkNotifications(userIds, notificationData);
  } catch (error) {
    logger.error('Send weather alert error:', error);
    throw error;
  }
};

// Send order update notification
exports.sendOrderNotification = async (userId, order, status) => {
  try {
    let title = '';
    let message = '';

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed';
        message = `Your order ${order.orderNumber} has been confirmed and is being processed.`;
        break;
      case 'shipped':
        title = 'Order Shipped';
        message = `Your order ${order.orderNumber} has been shipped!`;
        break;
      case 'delivered':
        title = 'Order Delivered';
        message = `Your order ${order.orderNumber} has been delivered. Thank you!`;
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        message = `Your order ${order.orderNumber} has been cancelled.`;
        break;
      default:
        title = 'Order Update';
        message = `Your order ${order.orderNumber} status has been updated.`;
    }

    return await this.createNotification(userId, {
      type: 'order_update',
      title,
      message,
      data: {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        status,
      },
      actionUrl: `/orders/${order._id}`,
      sendVia: {
        push: true,
        email: true,
        sms: false,
      },
    });
  } catch (error) {
    logger.error('Send order notification error:', error);
    throw error;
  }
};

// Send forum reply notification
exports.sendForumReplyNotification = async (postAuthorId, post, comment, commenterName) => {
  try {
    return await this.createNotification(postAuthorId, {
      type: 'forum_reply',
      title: 'New Reply on Your Post',
      message: `${commenterName} replied to your post: "${post.title}"`,
      data: {
        postId: post._id.toString(),
        commentId: comment._id.toString(),
      },
      actionUrl: `/forum/posts/${post._id}`,
      sendVia: {
        push: true,
        email: false,
        sms: false,
      },
    });
  } catch (error) {
    logger.error('Send forum reply notification error:', error);
    throw error;
  }
};

// Send disease detection notification
exports.sendDiseaseDetectionNotification = async (userId, detection) => {
  try {
    const disease = detection.topPrediction.diseaseName;
    const severity = detection.topPrediction.severity;

    return await this.createNotification(userId, {
      type: 'disease_detection',
      title: 'Disease Detection Complete',
      message: `${disease} detected with ${severity} severity. View treatment recommendations.`,
      data: {
        detectionId: detection._id.toString(),
        disease,
        severity,
      },
      actionUrl: `/crop-doctor/${detection._id}`,
      priority: severity === 'critical' ? 'high' : 'medium',
      sendVia: {
        push: true,
        email: false,
        sms: severity === 'critical',
      },
    });
  } catch (error) {
    logger.error('Send disease detection notification error:', error);
    throw error;
  }
};

// Mark notification as read
exports.markAsRead = async (notificationId) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      notificationId,
      { isRead: true, readAt: Date.now() },
      { new: true }
    );

    return notification;
  } catch (error) {
    logger.error('Mark notification as read error:', error);
    throw error;
  }
};

// Delete old notifications
exports.cleanupOldNotifications = async (daysOld = 30) => {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await Notification.deleteMany({
      createdAt: { $lt: cutoffDate },
      isRead: true,
    });

    logger.info(`Deleted ${result.deletedCount} old notifications`);

    return result;
  } catch (error) {
    logger.error('Cleanup old notifications error:', error);
    throw error;
  }
};

// Get unread notification count
exports.getUnreadCount = async (userId) => {
  try {
    const count = await Notification.countDocuments({
      user: userId,
      isRead: false,
    });

    return count;
  } catch (error) {
    logger.error('Get unread count error:', error);
    throw error;
  }
};
