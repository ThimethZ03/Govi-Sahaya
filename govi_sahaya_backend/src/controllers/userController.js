const User = require('../models/User');
const { uploadToStorage, deleteFromStorage } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: user,
    });
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch profile',
    });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, location, farmDetails } = req.body;

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    // Update fields
    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (location) user.location = location;
    if (farmDetails) user.farmDetails = farmDetails;

    await user.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Profile updated successfully',
      data: user,
    });
  } catch (error) {
    logger.error('Update profile error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Upload profile picture
// @route   POST /api/users/profile-picture
// @access  Private
exports.uploadProfilePicture = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    // Delete old profile picture if exists
    if (user.profilePicture) {
      try {
        const oldPath = user.profilePicture.split('/').pop();
        await deleteFromStorage(`profile_pictures/${oldPath}`);
      } catch (error) {
        logger.warn('Failed to delete old profile picture:', error);
      }
    }

    // Upload new picture to Firebase Storage
    const destination = `profile_pictures/${Date.now()}_${req.file.originalname}`;
    const imageUrl = await uploadToStorage(req.file, destination);

    // Update user
    user.profilePicture = imageUrl;
    await user.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profilePicture: imageUrl,
      },
    });
  } catch (error) {
    logger.error('Upload profile picture error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to upload profile picture',
    });
  }
};

// @desc    Delete profile picture
// @route   DELETE /api/users/profile-picture
// @access  Private
exports.deleteProfilePicture = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    if (!user.profilePicture) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No profile picture to delete',
      });
    }

    // Delete from Firebase Storage
    try {
      const filePath = user.profilePicture.split('/').pop();
      await deleteFromStorage(`profile_pictures/${filePath}`);
    } catch (error) {
      logger.warn('Failed to delete from storage:', error);
    }

    // Update user
    user.profilePicture = null;
    await user.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Profile picture deleted successfully',
    });
  } catch (error) {
    logger.error('Delete profile picture error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete profile picture',
    });
  }
};

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: user,
    });
  } catch (error) {
    logger.error('Get user by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch user',
    });
  }
};

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private/Admin
exports.getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = {};
    if (req.query.role) query.role = req.query.role;
    if (req.query.isActive) query.isActive = req.query.isActive === 'true';

    const users = await User.find(query)
      .select('-password')
      .limit(limit)
      .skip(skip)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: users,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all users error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch users',
    });
  }
};

// @desc    Deactivate user account
// @route   PUT /api/users/deactivate
// @access  Private
exports.deactivateAccount = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    user.isActive = false;
    await user.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Account deactivated successfully',
    });
  } catch (error) {
    logger.error('Deactivate account error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to deactivate account',
    });
  }
};

// @desc    Search users
// @route   GET /api/users/search
// @access  Private
exports.searchUsers = async (req, res) => {
  try {
    const { q, role } = req.query;

    if (!q) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const query = {
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
      isActive: true,
    };

    if (role) query.role = role;

    const users = await User.find(query)
      .select('name email phone profilePicture role location')
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
