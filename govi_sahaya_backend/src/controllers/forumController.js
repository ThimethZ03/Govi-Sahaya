// src/controllers/forumController.js

const Post    = require('../models/Post');
const Comment = require('../models/Comment');
const User    = require('../models/User');
const notificationService       = require('../services/notificationService');
const logger                    = require('../utils/logger');
const { uploadBuffer, deleteImage } = require('../utils/cloudinary');
const { HTTP_STATUS }           = require('../config/constants');

// ── GET /api/v1/forum/posts ───────────────────────────────────────────
exports.getAllPosts = async (req, res) => {
  try {
    const { category, search, isPinned } = req.query;
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const query = { isActive: true };
    if (category)              query.category = category;
    if (isPinned !== undefined) query.isPinned = isPinned === 'true';
    if (search)                 query.$text    = { $search: search };

    const posts = await Post.find(query)
      .populate('author', 'displayName email photoURL name')
      .sort({ isPinned: -1, createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Post.countDocuments(query);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: posts,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error('Get all posts error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch posts',
    });
  }
};

// ── GET /api/v1/forum/posts/:id ───────────────────────────────────────
exports.getPostById = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('author', 'displayName email photoURL name');

    if (!post) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Post not found',
    });

    post.views += 1;
    await post.save({ validateBeforeSave: false });

    return res.status(HTTP_STATUS.OK).json({ success: true, data: post });
  } catch (error) {
    logger.error('Get post by ID error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch post',
    });
  }
};

// ── POST /api/v1/forum/posts ──────────────────────────────────────────
exports.createPost = async (req, res) => {
  try {
    const { title, content, category, tags, location } = req.body;

    logger.info(`📝 Creating post by ${req.user.id} — files: ${req.files?.length || 0}`);

    // ✅ FIXED: pass 'govi_sahaya/forum' folder — was missing, caused misc/ fallback
    const images = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        try {
          const result = await uploadBuffer(
            file.buffer,
            file.originalname,
            'govi_sahaya/forum',   // ✅ correct folder
          );
          images.push({
            url:      result.secure_url,
            publicId: result.public_id,
            caption:  '',
          });
          logger.info(`✅ Forum image uploaded: ${result.secure_url}`);
        } catch (uploadErr) {
          logger.warn(`⚠️ Forum image upload failed (skipping): ${uploadErr.message}`);
        }
      }
    }

    const post = await Post.create({
      author:   req.user.id,
      title:    title   || content?.substring(0, 50) || 'Untitled',
      content:  content || '',
      category: category || 'general',
      tags:     tags ? tags.split(',').map((t) => t.trim()) : [],
      images,
      location: location || null,
    });

    await post.populate('author', 'displayName email photoURL name');
    logger.info(`✅ Post created: ${post._id.toString()}`);

    return res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Post created successfully',
      data:    post,
    });
  } catch (error) {
    logger.error('Create post error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false, message: error.message,
    });
  }
};

// ── PUT /api/v1/forum/posts/:id ───────────────────────────────────────
exports.updatePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Post not found',
    });

    if (post.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    const { title, content, category, tags, isResolved } = req.body;
    if (title)                   post.title      = title;
    if (content)                 post.content    = content;
    if (category)                post.category   = category;
    if (tags)                    post.tags       = tags.split(',').map((t) => t.trim());
    if (isResolved !== undefined) post.isResolved = isResolved;

    await post.save();
    await post.populate('author', 'displayName email photoURL name');

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Post updated successfully', data: post,
    });
  } catch (error) {
    logger.error('Update post error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false, message: error.message,
    });
  }
};

// ── DELETE /api/v1/forum/posts/:id ────────────────────────────────────
exports.deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Post not found',
    });

    if (post.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    // ✅ Delete all Cloudinary images before soft-deleting
    if (post.images && post.images.length > 0) {
      for (const img of post.images) {
        if (img.publicId) await deleteImage(img.publicId);
      }
    }

    post.isActive = false;
    await post.save();
    await Comment.updateMany({ post: req.params.id }, { isDeleted: true });

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Post deleted successfully',
    });
  } catch (error) {
    logger.error('Delete post error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to delete post',
    });
  }
};

// ── POST /api/v1/forum/posts/:id/like ────────────────────────────────
exports.likePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('author', '_id displayName name');
    if (!post) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Post not found',
    });

    const userId    = req.user.id;
    const likeIndex = post.likes.indexOf(userId);

    if (likeIndex > -1) {
      post.likes.splice(likeIndex, 1);
      post.likesCount = post.likes.length;
      await post.save({ validateBeforeSave: false });
      return res.status(HTTP_STATUS.OK).json({
        success: true, message: 'Post unliked',
        data: { liked: false, likesCount: post.likesCount },
      });
    }

    post.likes.push(userId);
    post.likesCount = post.likes.length;
    await post.save({ validateBeforeSave: false });

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
        logger.info(`👍 Like notification → ${post.author._id}`);
      } catch (notifErr) {
        logger.error('Like notification error:', notifErr.message);
      }
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Post liked',
      data: { liked: true, likesCount: post.likesCount },
    });
  } catch (error) {
    logger.error('Like post error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to like post',
    });
  }
};

// ── GET /api/v1/forum/posts/:id/comments ─────────────────────────────
exports.getPostComments = async (req, res) => {
  try {
    const comments = await Comment.find({
      post:          req.params.id,
      isDeleted:     false,
      parentComment: null,
    })
      .populate('author', 'displayName email photoURL name')
      .sort({ createdAt: -1 });

    return res.status(HTTP_STATUS.OK).json({
      success: true, data: comments, count: comments.length,
    });
  } catch (error) {
    logger.error('Get post comments error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch comments',
    });
  }
};

// ── POST /api/v1/forum/posts/:id/comments ────────────────────────────
exports.addComment = async (req, res) => {
  try {
    const { content, parentComment } = req.body;

    const post = await Post.findById(req.params.id)
      .populate('author', '_id displayName name');
    if (!post) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Post not found',
    });

    const comment = await Comment.create({
      post:          req.params.id,
      author:        req.user.id,
      content,
      parentComment: parentComment || null,
    });

    post.commentsCount += 1;
    await post.save({ validateBeforeSave: false });
    await comment.populate('author', 'displayName email photoURL name');

    if (post.author._id.toString() !== req.user.id) {
      try {
        const commenter     = await User.findById(req.user.id).select('displayName name');
        const commenterName = commenter?.displayName || commenter?.name || 'Someone';
        const postTitle     = (post.title || 'your post').substring(0, 50);
        await notificationService.createNotification(post.author._id, {
          type:      'forum_reply',
          title:     '💬 New Comment on Your Post',
          message:   `${commenterName} commented on "${postTitle}"`,
          data:      { postId: post._id.toString(), commentId: comment._id.toString() },
          actionUrl: `/forum/posts/${post._id}`,
          priority:  'medium',
          sendVia:   { push: true, email: false, sms: false },
        });
        logger.info(`💬 Comment notification → ${post.author._id}`);
      } catch (notifErr) {
        logger.error('Comment notification error:', notifErr.message);
      }
    }

    return res.status(HTTP_STATUS.CREATED).json({
      success: true, message: 'Comment added successfully', data: comment,
    });
  } catch (error) {
    logger.error('Add comment error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false, message: error.message,
    });
  }
};

// ── PUT /api/v1/forum/comments/:id ───────────────────────────────────
exports.updateComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);
    if (!comment) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Comment not found',
    });

    if (comment.author.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    comment.content  = req.body.content;
    comment.isEdited = true;
    comment.editedAt = Date.now();
    await comment.save();

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Comment updated successfully', data: comment,
    });
  } catch (error) {
    logger.error('Update comment error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false, message: error.message,
    });
  }
};

// ── DELETE /api/v1/forum/comments/:id ────────────────────────────────
exports.deleteComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);
    if (!comment) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Comment not found',
    });

    if (comment.author.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    comment.isDeleted = true;
    await comment.save();
    await Post.findByIdAndUpdate(comment.post, { $inc: { commentsCount: -1 } });

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Comment deleted successfully',
    });
  } catch (error) {
    logger.error('Delete comment error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to delete comment',
    });
  }
};

// ── POST /api/v1/forum/comments/:id/like ─────────────────────────────
exports.likeComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);
    if (!comment) return res.status(HTTP_STATUS.NOT_FOUND).json({
      success: false, message: 'Comment not found',
    });

    const userId    = req.user.id;
    const likeIndex = comment.likes.indexOf(userId);

    if (likeIndex > -1) {
      comment.likes.splice(likeIndex, 1);
    } else {
      comment.likes.push(userId);
    }
    comment.likesCount = comment.likes.length;
    await comment.save({ validateBeforeSave: false });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: likeIndex > -1 ? 'Comment unliked' : 'Comment liked',
      data:    { likesCount: comment.likesCount },
    });
  } catch (error) {
    logger.error('Like comment error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to like comment',
    });
  }
};

// ── GET /api/v1/forum/my-posts ────────────────────────────────────────
exports.getMyPosts = async (req, res) => {
  try {
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const posts = await Post.find({ author: req.user.id, isActive: true })
      .populate('author', 'displayName email photoURL name')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Post.countDocuments({ author: req.user.id, isActive: true });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: posts,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error('Get my posts error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch posts',
    });
  }
};
