// routes/notificationRoutes.js

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

// ─────────────────────────────────────────────────────────
// ✅ STATIC / SPECIFIC routes — ALL must come before /:id
// ─────────────────────────────────────────────────────────

// GET
router.get('/',             getAllNotifications);
router.get('/unread/count', getUnreadCount);     // ✅ before /:id

// PUT
router.put('/read-all',     markAllAsRead);      // ✅ before /:id/read

// DELETE
router.delete('/',          clearAllNotifications);

// POST (admin)
router.post('/',            authorize('admin'), createNotification);
router.post('/bulk',        authorize('admin'), sendBulkNotifications); // ✅ before /:id

// ─────────────────────────────────────────────────────────
// ✅ PARAMETERIZED routes — always last
// ─────────────────────────────────────────────────────────
router.get('/:id',          getNotificationById);
router.put('/:id/read',     markAsRead);
router.delete('/:id',       deleteNotification);

module.exports = router;
