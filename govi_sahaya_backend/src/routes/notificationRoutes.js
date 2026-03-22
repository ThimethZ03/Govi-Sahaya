const express = require('express');
const router = express.Router();
const {
  getAllNotifications,
  getNotificationById,
  createNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  getUnreadCount,
  sendBulkNotifications,
} = require('../controllers/notificationController');
const { protect, authorize } = require('../middleware/authMiddleware');

// All routes are protected
router.use(protect);

// User notification routes
router.get('/', getAllNotifications);
router.get('/unread/count', getUnreadCount);
router.get('/:id', getNotificationById);
router.put('/read-all', markAllAsRead);
router.put('/:id/read', markAsRead);
router.delete('/:id', deleteNotification);
router.delete('/', clearAllNotifications);

// Admin only routes
router.post('/', authorize('admin'), createNotification);
router.post('/bulk', authorize('admin'), sendBulkNotifications);

module.exports = router;

