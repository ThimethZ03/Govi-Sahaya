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

// @desc    Create new guide
// @route   POST /api/knowledge/guides
// @access  Private/Expert/Admin
exports.createGuide = async (req, res) => {
  try {
    const guideData = {
      ...req.body,
      author: req.user.id,
    };

    if (req.file) {
      const destination = `guide_covers/${Date.now()}_${req.file.originalname}`;
      guideData.coverImage = await uploadToStorage(req.file, destination);
    }

    if (typeof req.body.steps === 'string') guideData.steps = JSON.parse(req.body.steps);
    if (typeof req.body.materials === 'string') guideData.materials = JSON.parse(req.body.materials);
    if (typeof req.body.crops === 'string') guideData.crops = JSON.parse(req.body.crops);
    if (typeof req.body.tags === 'string') guideData.tags = JSON.parse(req.body.tags);

    const guide = await Guide.create(guideData);
    await guide.populate('author', 'name profilePicture role');

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Guide created successfully',
      data: guide,
    });
  } catch (error) {
    logger.error('Create guide error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update guide
// @route   PUT /api/knowledge/guides/:id
// @access  Private/Expert/Admin
exports.updateGuide = async (req, res) => {
  try {
    let guide = await Guide.findById(req.params.id);

    if (!guide) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Guide not found',
      });
    }

    if (guide.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this guide',
      });
    }

    if (req.file) {
      const destination = `guide_covers/${Date.now()}_${req.file.originalname}`;
      req.body.coverImage = await uploadToStorage(req.file, destination);
    }

    // NOTE: JSON parsing for update fields missing here (will fix in next commit)
    guide = await Guide.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    }).populate('author', 'name profilePicture role');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Guide updated successfully',
      data: guide,
    });
  } catch (error) {
    logger.error('Update guide error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Delete guide (soft delete)
// @route   DELETE /api/knowledge/guides/:id
// @access  Private/Expert/Admin
exports.deleteGuide = async (req, res) => {
  try {
    const guide = await Guide.findById(req.params.id);

    if (!guide) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Guide not found',
      });
    }

    if (guide.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this guide',
      });
    }

    guide.isPublished = false;
    await guide.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Guide deleted successfully',
    });
  } catch (error) {
    logger.error('Delete guide error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete guide',
    });
  }
};