const fs = require('fs');
const path = require('path');
const User = require('../models/User');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');

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
    const {
      name,
      phone,
      location,
      farmDetails,
      birthday,
      gender,
      farmLocation,
    } = req.body;

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    if (name !== undefined) user.name = name;
    if (phone !== undefined) user.phone = phone;

    if (location !== undefined) {
      user.location = {
        district: location.district ?? user.location?.district ?? '',
        province: location.province ?? user.location?.province ?? '',
      };
    }

    if (farmDetails !== undefined) {
      user.farmDetails = {
        farmSize:     farmDetails.farmSize     ?? user.farmDetails?.farmSize,
        farmSizeUnit: farmDetails.farmSizeUnit ?? user.farmDetails?.farmSizeUnit ?? 'acres',
        mainCrops:    farmDetails.mainCrops    ?? user.farmDetails?.mainCrops ?? [],
      };
    }

    if (birthday !== undefined) user.birthday = birthday;
    if (gender !== undefined) user.gender = gender;
    if (farmLocation !== undefined) user.farmLocation = farmLocation;

    await user.save();

    logger.info(`✅ Profile updated for user: ${user._id}`);

    const updatedUser = await User.findById(user._id).select('-password');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser,
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

    logger.info(`📁 File received: ${req.file.originalname} (${req.file.size} bytes)`);

    const user = await User.findById(req.user.id);

    if (!user) {
      // ✅ Clean up uploaded file if user not found
      fs.unlink(req.file.path, () => {});
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    // ✅ Delete old picture from disk if it exists
    if (user.profilePicture) {
      const oldFilePath = path.join(__dirname, '../../', user.profilePicture);
      if (fs.existsSync(oldFilePath)) {
        fs.unlink(oldFilePath, (err) => {
          if (err) logger.warn(`⚠️ Could not delete old profile picture: ${err.message}`);
          else logger.info(`🗑️ Old profile picture deleted: ${oldFilePath}`);
        });
      }
    }

    // ✅ Save relative URL path to MongoDB
    const imageUrl = `/uploads/profile_pictures/${req.file.filename}`;
    user.profilePicture = imageUrl;
    await user.save();

    logger.info(`🖼️ Profile picture saved: ${imageUrl}`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profilePicture: imageUrl,
      },
    });
  } catch (error) {
    // ✅ Clean up uploaded file on error
    if (req.file) fs.unlink(req.file.path, () => {});
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

    // ✅ Delete file from disk
    const filePath = path.join(__dirname, '../../', user.profilePicture);
    if (fs.existsSync(filePath)) {
      fs.unlink(filePath, (err) => {
        if (err) logger.warn(`⚠️ Could not delete profile picture file: ${err.message}`);
        else logger.info(`🗑️ Profile picture deleted from disk: ${filePath}`);
      });
    }

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
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const query = {};
    if (req.query.role)     query.role     = req.query.role;
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
        { name:  { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
      isActive: true,
    };

    if (role) query.role = role;

    const users = await User.find(query)
      .select('name email phone profilePicture role location farmLocation')
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
