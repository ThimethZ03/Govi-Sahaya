const Post    = require('../models/Post');
const Comment = require('../models/Comment');
const User    = require('../models/User');
const notificationService = require('../services/notificationService');
const logger  = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// ── Get all posts ─────────────────────────────────────────────────────────────
// @route   GET /api/forum/posts
// @access  Public
exports.getAllPosts = async (req, res) => {
  try {
    const { category, search, isPinned } = req.query;
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const query = { isActive: true };

    if (category)            query.category = category;
    if (isPinned !== undefined) query.isPinned = isPinned === 'true';
    if (search)              query.$text = { $search: search };

    const posts = await Post.find(query)
      .populate('author', 'displayName email photoURL')
      .sort({ isPinned: -1, createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Post.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all posts error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch posts',
    });
  }
};

// ── Get post by ID ────────────────────────────────────────────────────────────
// @route   GET /api/forum/posts/:id
// @access  Public
exports.getPostById = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('author', 'displayName email photoURL');

    if (!post) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Post not found',
      });
    }

    post.views += 1;
    await post.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: post,
    });
  } catch (error) {
    logger.error('Get post by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch post',
    });
  }
};

// ── Create post ───────────────────────────────────────────────────────────────
// @route   POST /api/forum/posts
// @access  Private
exports.createPost = async (req, res) => {
  try {
    const { title, content, category, tags, location } = req.body;

    logger.info('📝 Creating post...', {
      author:    req.user.id,
      hasFiles:  !!req.files,
      fileCount: req.files?.length || 0,
    });

    let images = [];

    if (req.files && req.files.length > 0) {
      images = req.files.map((file) => ({
        url:     `/uploads/forum_posts/${file.filename}`,
        caption: '',
      }));
      logger.info(`✅ ${images.length} image(s) saved locally:`,
        images.map((img) => img.url));
    }

    const post = await Post.create({
      author:   req.user.id,
      title:    title    || 'Untitled',
      content:  content  || '',
      category: category || 'general',
      tags:     tags ? tags.split(',').map((t) => t.trim()) : [],
      images,
      location: location || null,
    });

    await post.populate('author', 'displayName email photoURL');

    logger.info('✅ Post created successfully:', post._id);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Post created successfully',
      data:    post,
    });
  } catch (error) {
    logger.error('Create post error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// ── Update post ───────────────────────────────────────────────────────────────
// @route   PUT /api/forum/posts/:id
// @access  Private
exports.updatePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Post not found',
      });
    }

    if (post.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this post',
      });
    }

    const { title, content, category, tags, isResolved } = req.body;

    if (title)              post.title    = title;
    if (content)            post.content  = content;
    if (category)           post.category = category;
    if (tags)               post.tags     = tags.split(',').map((t) => t.trim());
    if (isResolved !== undefined) post.isResolved = isResolved;

    await post.save();
    await post.populate('author', 'displayName email photoURL');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Post updated successfully',
      data:    post,
    });
  } catch (error) {
    logger.error('Update post error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// ── Delete post ───────────────────────────────────────────────────────────────
// @route   DELETE /api/forum/posts/:id
// @access  Private
exports.deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Post not found',
      });
    }

    if (post.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this post',
      });
    }

    post.isActive = false;
    await post.save();

    await Comment.updateMany({ post: req.params.id }, { isDeleted: true });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Post deleted successfully',
    });
  } catch (error) {
    logger.error('Delete post error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete post',
    });
  }
};

// ── Like / Unlike post ────────────────────────────────────────────────────────
// @route   POST /api/forum/posts/:id/like
// @access  Private
exports.likePost = async (req, res) => {
  try {
    // ✅ populate author so we can send notification
    const post = await Post.findById(req.params.id)
      .populate('author', '_id displayName name');

    if (!post) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Post not found',
      });
    }

    const userId    = req.user.id;
    const likeIndex = post.likes.indexOf(userId);

    if (likeIndex > -1) {
      // ── Unlike — no notification ────────────────────────────────
      post.likes.splice(likeIndex, 1);
      post.likesCount = post.likes.length;
      await post.save({ validateBeforeSave: false });

      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Post unliked',
        data:    { liked: false, likesCount: post.likesCount },
      });
    } else {
      // ── Like ─────────────────────────────────────────────────────
      post.likes.push(userId);
      post.likesCount = post.likes.length;
      await post.save({ validateBeforeSave: false });

      // ✅ Notify post author (skip if author liked their own post)
      if (post.author._id.toString() !== userId) {
        try {
          const liker     = await User.findById(userId).select('displayName name');
          const likerName = liker?.displayName || liker?.name || 'Someone';
          const postTitle = (post.title || 'your post').substring(0, 50);

          await notificationService.createNotification(post.author._id, {
            type:      'general',
            title:     '👍 Someone liked your post',
            message:   `${likerName} liked "${postTitle}"`,
            data:      { postId: post._id.toString() },
            actionUrl: `/forum/posts/${post._id}`,
            priority:  'low',
            sendVia:   { push: true, email: false, sms: false },
          });

          logger.info(`👍 Like notification → post author ${post.author._id}`);
        } catch (notifErr) {
          logger.error('Like notification error:', notifErr.message);
        }
      }

      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Post liked',
        data:    { liked: true, likesCount: post.likesCount },
      });
    }
  } catch (error) {
    logger.error('Like post error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to like post',
    });
  }
};

// ── Get comments for a post ───────────────────────────────────────────────────
// @route   GET /api/forum/posts/:id/comments
// @access  Public
exports.getPostComments = async (req, res) => {
  try {
    const comments = await Comment.find({
      post:          req.params.id,
      isDeleted:     false,
      parentComment: null,
    })
      .populate('author', 'displayName email photoURL')
      .sort({ createdAt: -1 });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data:    comments,
      count:   comments.length,
    });
  } catch (error) {
    logger.error('Get post comments error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch comments',
    });
  }
};

// ── Add comment ───────────────────────────────────────────────────────────────
// @route   POST /api/forum/posts/:id/comments
// @access  Private
exports.addComment = async (req, res) => {
  try {
    const { content, parentComment } = req.body;

    // ✅ populate author so we can send notification
    const post = await Post.findById(req.params.id)
      .populate('author', '_id displayName name');

    if (!post) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Post not found',
      });
    }

    const comment = await Comment.create({
      post:          req.params.id,
      author:        req.user.id,
      content,
      parentComment: parentComment || null,
    });

    post.commentsCount += 1;
    await post.save({ validateBeforeSave: false });

    await comment.populate('author', 'displayName email photoURL');

    // ✅ Notify post author (skip if author comments on their own post)
    if (post.author._id.toString() !== req.user.id) {
      try {
        const commenter     = await User.findById(req.user.id).select('displayName name');
        const commenterName = commenter?.displayName || commenter?.name || 'Someone';
        const postTitle     = (post.title || 'your post').substring(0, 50);

        await notificationService.createNotification(post.author._id, {
          type:      'forum_reply',
          title:     '💬 New Comment on Your Post',
          message:   `${commenterName} commented on "${postTitle}"`,
          data: {
            postId:    post._id.toString(),
            commentId: comment._id.toString(),
          },
          actionUrl: `/forum/posts/${post._id}`,
          priority:  'medium',
          sendVia:   { push: true, email: false, sms: false },
        });

        logger.info(`💬 Comment notification → post author ${post.author._id}`);
      } catch (notifErr) {
        // Never block the comment response if notification fails
        logger.error('Comment notification error:', notifErr.message);
      }
    }

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Comment added successfully',
      data:    comment,
    });
  } catch (error) {
    logger.error('Add comment error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// ── Update comment ────────────────────────────────────────────────────────────
// @route   PUT /api/forum/comments/:id
// @access  Private
exports.updateComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Comment not found',
      });
    }

    if (comment.author.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this comment',
      });
    }

    comment.content  = req.body.content;
    comment.isEdited = true;
    comment.editedAt = Date.now();
    await comment.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Comment updated successfully',
      data:    comment,
    });
  } catch (error) {
    logger.error('Update comment error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// ── Delete comment ────────────────────────────────────────────────────────────
// @route   DELETE /api/forum/comments/:id
// @access  Private
exports.deleteComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Comment not found',
      });
    }

    if (comment.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this comment',
      });
    }

    comment.isDeleted = true;
    await comment.save();

    await Post.findByIdAndUpdate(comment.post, {
      $inc: { commentsCount: -1 },
    });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Comment deleted successfully',
    });
  } catch (error) {
    logger.error('Delete comment error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete comment',
    });
  }
};

// ── Like / Unlike comment ─────────────────────────────────────────────────────
// @route   POST /api/forum/comments/:id/like
// @access  Private
exports.likeComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Comment not found',
      });
    }

    const userId    = req.user.id;
    const likeIndex = comment.likes.indexOf(userId);

    if (likeIndex > -1) {
      comment.likes.splice(likeIndex, 1);
    } else {
      comment.likes.push(userId);
    }

    comment.likesCount = comment.likes.length;
    await comment.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: likeIndex > -1 ? 'Comment unliked' : 'Comment liked',
      data:    { likesCount: comment.likesCount },
    });
  } catch (error) {
    logger.error('Like comment error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to like comment',
    });
  }
};

// ── Get my posts ──────────────────────────────────────────────────────────────
// @route   GET /api/forum/my-posts
// @access  Private
exports.getMyPosts = async (req, res) => {
  try {
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const posts = await Post.find({ author: req.user.id, isActive: true })
      .populate('author', 'displayName email photoURL')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Post.countDocuments({
      author:   req.user.id,
      isActive: true,
    });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get my posts error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch posts',
    });
  }
};
