const express = require('express');
const router = express.Router();

const {
  getProfile,
  updateProfile,
  uploadProfilePicture,
  deleteProfilePicture,
  getUserById,
  getAllUsers,
  deactivateAccount,
  searchUsers,
  deleteAccount, // ✅ added
} = require('../controllers/userController');

const { protect, authorize } = require('../middleware/authMiddleware');
const {
  uploadProfilePicture: uploadProfilePictureMiddleware,
} = require('../middleware/uploadMiddleware');

// ── Profile ────────────────────────────────────────────────────────────
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);
router.delete('/profile', protect, deleteAccount); // ✅ added

// ── Profile Picture ────────────────────────────────────────────────────
router.post(
  '/profile-picture',
  protect,
  uploadProfilePictureMiddleware('image'),
  uploadProfilePicture
);
router.delete('/profile-picture', protect, deleteProfilePicture);

// ── Account ────────────────────────────────────────────────────────────
router.put('/deactivate', protect, deactivateAccount);

// ── Search — must be before /:id ───────────────────────────────────────
router.get('/search', protect, searchUsers);

// ── Get user by ID ─────────────────────────────────────────────────────
router.get('/:id', protect, getUserById);

// ── Admin only ─────────────────────────────────────────────────────────
router.get('/', protect, authorize('admin'), getAllUsers);

module.exports = router;