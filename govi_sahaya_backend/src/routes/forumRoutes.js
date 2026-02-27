const express = require('express');
const router = express.Router();

const {
  getAllPosts,
  getPostById,
  createPost,
  updatePost,
  deletePost,
  likePost,
  getPostComments,
  addComment,
  updateComment,
  deleteComment,
  likeComment,
  getMyPosts,
} = require('../controllers/forumController');

const { protect } = require('../middleware/authMiddleware');

// ✅ CHANGED: use forum uploader (saves into /uploads/forum_posts)
const { uploadForumImages } = require('../middleware/uploadMiddleware');

// Public routes
router.get('/posts', getAllPosts);
router.get('/posts/:id', getPostById);
router.get('/posts/:id/comments', getPostComments);

// Protected routes
router.use(protect);

// Post routes
router.post('/posts', uploadForumImages('images', 5), createPost);
router.put('/posts/:id', updatePost);
router.delete('/posts/:id', deletePost);
router.post('/posts/:id/like', likePost);
router.get('/my-posts', getMyPosts);

// Comment routes
router.post('/posts/:id/comments', addComment);
router.put('/comments/:id', updateComment);
router.delete('/comments/:id', deleteComment);
router.post('/comments/:id/like', likeComment);

module.exports = router;