const express = require('express');
const router = express.Router();
const {
  sendMessage,
  getConversations,
  getMessages,
  markAsRead,
  deleteMessage,
  getUnreadCount,
  searchUsers,
  getExperts,
  blockUser,
  reportUser,
} = require('../controllers/safetyController');
const { protect } = require('../middleware/authMiddleware'); // ✅ Correct



// All routes are protected
router.use(protect);

// Message routes
router.post('/messages', sendMessage);
router.get('/conversations', getConversations);
router.get('/messages/unread/count', getUnreadCount);
router.get('/messages/:userId', getMessages);
router.put('/messages/:id/read', markAsRead);
router.delete('/messages/:id', deleteMessage);

// User search routes
router.get('/users/search', searchUsers);
router.get('/experts', getExperts);

// Safety routes
router.post('/block/:userId', blockUser);
router.post('/report', reportUser);

module.exports = router;

