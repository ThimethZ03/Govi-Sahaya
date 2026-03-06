const Guide = require('../models/Guide');
const { uploadToStorage } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS, KNOWLEDGE_CATEGORIES } = require('../config/constants');

// @desc    Get all guides
// @route   GET /api/knowledge/guides
// @access  Public
exports.getAllGuides = async (req, res) => {
  try {
    const { category, difficulty, search, isFeatured } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { isPublished: true };

    if (category) query.category = category;
    if (difficulty) query.difficulty = difficulty;
    if (isFeatured !== undefined) query.isFeatured = isFeatured === 'true';
    if (search) query.$text = { $search: search };

    const guides = await Guide.find(query)
      .populate('author', 'name profilePicture role')
      .sort({ isFeatured: -1, createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Guide.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: guides,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all guides error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch guides',
    });
  }
};