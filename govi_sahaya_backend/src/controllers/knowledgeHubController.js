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

// @desc    Get guide by ID
// @route   GET /api/knowledge/guides/:id
// @access  Public
exports.getGuideById = async (req, res) => {
  try {
    const guide = await Guide.findById(req.params.id)
      .populate('author', 'name profilePicture role')
      .populate('relatedGuides');

    if (!guide) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Guide not found',
      });
    }

    guide.views += 1;
    await guide.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({ success: true, data: guide });
  } catch (error) {
    logger.error('Get guide by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch guide',
    });
  }
};

// @desc    Get guide by slug
// @route   GET /api/knowledge/guides/slug/:slug
// @access  Public
exports.getGuideBySlug = async (req, res) => {
  try {
    const guide = await Guide.findOne({ slug: req.params.slug })
      .populate('author', 'name profilePicture role')
      .populate('relatedGuides');

    if (!guide) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Guide not found',
      });
    }

    guide.views += 1;
    await guide.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({ success: true, data: guide });
  } catch (error) {
    logger.error('Get guide by slug error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch guide',
    });
  }
};