const News = require('../models/News');
const { fetchAgriNewsFromEsana, getKeywordStats } = require('../services/esanaNewsService');
const { fetchAgriNews } = require('../services/newsService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Get all news
// @route   GET /api/news
// @access  Public
exports.getAllNews = async (req, res) => {
  try {
    const { category, search, language } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { isPublished: true };

    if (category) query.category = category;
    if (language) query.language = language;
    if (search) {
      query.$text = { $search: search };
    }

    const news = await News.find(query)
      .sort({ publishedDate: -1 })
      .limit(limit)
      .skip(skip);

    const total = await News.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: news,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch news',
    });
  }
};

// @desc    Get news by ID
// @route   GET /api/news/:id
// @access  Public
exports.getNewsById = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'News not found',
      });
    }

    // Increment views
    news.views += 1;
    await news.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: news,
    });
  } catch (error) {
    logger.error('Get news by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch news',
    });
  }
};

// @desc    Get featured news
// @route   GET /api/news/featured
// @access  Public
exports.getFeaturedNews = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 5;

    const news = await News.find({ isFeatured: true, isPublished: true })
      .sort({ publishedDate: -1 })
      .limit(limit);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: news,
    });
  } catch (error) {
    logger.error('Get featured news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch featured news',
    });
  }
};

// @desc    Get latest news
// @route   GET /api/news/latest
// @access  Public
exports.getLatestNews = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const news = await News.find({ isPublished: true })
      .sort({ publishedDate: -1 })
      .limit(limit);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: news,
    });
  } catch (error) {
    logger.error('Get latest news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch latest news',
    });
  }
};

// @desc    Sync external news (NewsAPI or other)
// @route   POST /api/news/sync
// @access  Private/Admin
exports.syncExternalNews = async (req, res) => {
  try {
    const externalNews = await fetchAgriNews();

    const savedNews = [];
    for (const newsItem of externalNews) {
      const existingNews = await News.findOne({
        'externalSource.apiId': newsItem.externalSource.apiId,
      });

      if (!existingNews) {
        const news = await News.create(newsItem);
        savedNews.push(news);
      }
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: `Synced ${savedNews.length} new articles`,
      data: savedNews,
    });
  } catch (error) {
    logger.error('Sync external news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to sync news',
      error: error.message,
    });
  }
};

// @desc    Sync Helakuru Esana news (WITH 1000+ KEYWORD FILTERING)
// @route   POST /api/news/sync/esana
// @access  Private/Admin
exports.syncEsanaNews = async (req, res) => {
  try {
    logger.info('🔄 Starting Helakuru Esana news sync with agricultural filtering...');
    
    const esanaNews = await fetchAgriNewsFromEsana();
    
    if (!esanaNews || esanaNews.length === 0) {
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'No agriculture news found to sync',
        data: {
          totalFetched: 0,
          newArticles: 0,
          skippedArticles: 0,
        },
      });
    }

    const savedNews = [];
    const skippedNews = [];
    const errors = [];

    for (const newsItem of esanaNews) {
      try {
        // Check if news already exists
        const existingNews = await News.findOne({
          'externalSource.apiId': newsItem.externalSource.apiId,
        });

        if (!existingNews) {
          const news = await News.create(newsItem);
          savedNews.push(news);
          logger.info(`✅ Saved: ${news.title}`);
        } else {
          skippedNews.push(newsItem.title);
          logger.debug(`⏭️ Skipped existing: ${newsItem.title}`);
        }
      } catch (err) {
        logger.error(`❌ Failed to save news: ${err.message}`);
        errors.push({ title: newsItem.title, error: err.message });
      }
    }

    logger.info(`✅ Sync complete: ${savedNews.length} new, ${skippedNews.length} skipped, ${errors.length} errors`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: `Successfully synced ${savedNews.length} new agriculture news from Helakuru Esana`,
      data: {
        totalFetched: esanaNews.length,
        newArticles: savedNews.length,
        skippedArticles: skippedNews.length,
        errors: errors.length,
        savedNews: savedNews.slice(0, 10), // Return first 10
      },
    });
  } catch (error) {
    logger.error('❌ Sync Esana news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to sync Esana news',
      error: error.message,
    });
  }
};

// @desc    Get agriculture news statistics
// @route   GET /api/news/stats/agriculture
// @access  Public
exports.getAgricultureStats = async (req, res) => {
  try {
    const categoryStats = await News.aggregate([
      { $match: { isPublished: true } },
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          totalViews: { $sum: '$views' },
          totalLikes: { $sum: '$likes' },
          totalShares: { $sum: '$shares' },
        },
      },
      { $sort: { count: -1 } },
    ]);

    const totalNews = await News.countDocuments({ isPublished: true });
    const esanaNews = await News.countDocuments({
      isPublished: true,
      'externalSource.name': 'Helakuru Esana',
    });

    const keywordStats = getKeywordStats();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: {
        totalNews,
        esanaNews,
        categoryStats,
        keywordStats,
      },
    });
  } catch (error) {
    logger.error('Get agriculture stats error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch statistics',
    });
  }
};

// @desc    Create news (Admin only)
// @route   POST /api/news
// @access  Private/Admin
exports.createNews = async (req, res) => {
  try {
    const news = await News.create(req.body);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'News created successfully',
      data: news,
    });
  } catch (error) {
    logger.error('Create news error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update news (Admin only)
// @route   PUT /api/news/:id
// @access  Private/Admin
exports.updateNews = async (req, res) => {
  try {
    const news = await News.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!news) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'News not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'News updated successfully',
      data: news,
    });
  } catch (error) {
    logger.error('Update news error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Delete news (Admin only)
// @route   DELETE /api/news/:id
// @access  Private/Admin
exports.deleteNews = async (req, res) => {
  try {
    const news = await News.findByIdAndDelete(req.params.id);

    if (!news) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'News not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'News deleted successfully',
    });
  } catch (error) {
    logger.error('Delete news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete news',
    });
  }
};

// @desc    Like news
// @route   POST /api/news/:id/like
// @access  Private
exports.likeNews = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'News not found',
      });
    }

    news.likes += 1;
    await news.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'News liked successfully',
      data: { likes: news.likes },
    });
  } catch (error) {
    logger.error('Like news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to like news',
    });
  }
};

// @desc    Share news
// @route   POST /api/news/:id/share
// @access  Private
exports.shareNews = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'News not found',
      });
    }

    news.shares += 1;
    await news.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'News shared successfully',
      data: { shares: news.shares },
    });
  } catch (error) {
    logger.error('Share news error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to share news',
    });
  }
};
