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
} = require('../controllers/userController');

const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadProfilePicture: uploadProfilePictureMiddleware } = require('../middleware/uploadMiddleware');

// Protected routes
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);

router.post(
  '/profile-picture',
  protect,
  uploadProfilePictureMiddleware('profilePicture'),
  uploadProfilePicture
);

router.delete('/profile-picture', protect, deleteProfilePicture);
router.put('/deactivate', protect, deactivateAccount);
router.get('/search', protect, searchUsers);

// Get user by ID
router.get('/:id', protect, getUserById);

// Admin only routes
router.get('/', protect, authorize('admin'), getAllUsers);

module.exports = router;