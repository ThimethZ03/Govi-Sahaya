const express = require('express');
const router = express.Router();
const {
  // Shop item controllers
  getAllItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  addReview,
  getFeaturedItems,
  // Cart controllers
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  // Order controllers
  createOrder,
  getUserOrders,
  getOrderById,
  cancelOrder,
  updateOrderStatus,
} = require('../controllers/shopController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadMultiple } = require('../middleware/uploadMiddleware');

// ========== SHOP ITEMS ==========

// Public routes
router.get('/items', getAllItems);
router.get('/items/featured', getFeaturedItems);
router.get('/items/:id', getItemById);

// Protected routes
router.post('/items/:id/review', protect, addReview);

// Vendor only routes
router.post('/items', protect, authorize('vendor', 'admin'), uploadMultiple('images', 5), createItem);
router.put('/items/:id', protect, authorize('vendor', 'admin'), uploadMultiple('images', 5), updateItem);
router.delete('/items/:id', protect, authorize('vendor', 'admin'), deleteItem);

// ========== CART ==========

// All cart routes are protected
router.get('/cart', protect, getCart);
router.post('/cart', protect, addToCart);
router.put('/cart/:productId', protect, updateCartItem);
router.delete('/cart/:productId', protect, removeFromCart);
router.delete('/cart', protect, clearCart);

// ========== ORDERS ==========

// All order routes are protected
router.post('/orders', protect, createOrder);
router.get('/orders', protect, getUserOrders);
router.get('/orders/:id', protect, getOrderById);
router.put('/orders/:id/cancel', protect, cancelOrder);

// Admin/Vendor routes
router.put('/orders/:id/status', protect, authorize('admin', 'vendor'), updateOrderStatus);

module.exports = router;

