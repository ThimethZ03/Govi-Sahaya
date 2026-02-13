const ShopItem = require('../models/ShopItem');
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const { uploadToStorage } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// ========== SHOP ITEM CONTROLLERS ==========

// @desc    Get all shop items
// @route   GET /api/shop/items
// @access  Public
exports.getAllItems = async (req, res) => {
  try {
    const { category, search, minPrice, maxPrice, isOrganic, isFeatured } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { isAvailable: true };

    if (category) query.category = category;
    if (isOrganic !== undefined) query.isOrganic = isOrganic === 'true';
    if (isFeatured !== undefined) query.isFeatured = isFeatured === 'true';
    
    if (minPrice || maxPrice) {
      query['price.original'] = {};
      if (minPrice) query['price.original'].$gte = parseFloat(minPrice);
      if (maxPrice) query['price.original'].$lte = parseFloat(maxPrice);
    }

    if (search) {
      query.$text = { $search: search };
    }

    const items = await ShopItem.find(query)
      .populate('vendor', 'name phone location')
      .sort({ isFeatured: -1, sales: -1 })
      .limit(limit)
      .skip(skip);

    const total = await ShopItem.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: items,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all items error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch shop items',
    });
  }
};

// @desc    Get item by ID
// @route   GET /api/shop/items/:id
// @access  Public
exports.getItemById = async (req, res) => {
  try {
    const item = await ShopItem.findById(req.params.id)
      .populate('vendor', 'name phone email location')
      .populate('reviews.user', 'name profilePicture');

    if (!item) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Item not found',
      });
    }

    // Increment views
    item.views += 1;
    await item.save({ validateBeforeSave: false });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: item,
    });
  } catch (error) {
    logger.error('Get item by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch item',
    });
  }
};

// @desc    Create shop item (Vendor only)
// @route   POST /api/shop/items
// @access  Private/Vendor
exports.createItem = async (req, res) => {
  try {
    const itemData = {
      ...req.body,
      vendor: req.user.id,
    };

    // Handle multiple images upload
    if (req.files && req.files.length > 0) {
      const imagePromises = req.files.map(async (file, index) => {
        const destination = `shop_products/${Date.now()}_${file.originalname}`;
        const url = await uploadToStorage(file, destination);
        return {
          url,
          isPrimary: index === 0,
          alt: file.originalname,
        };
      });
      itemData.images = await Promise.all(imagePromises);
    }

    // Parse JSON fields if sent as strings
    if (typeof req.body.specifications === 'string') {
      itemData.specifications = JSON.parse(req.body.specifications);
    }
    if (typeof req.body.stock === 'string') {
      itemData.stock = JSON.parse(req.body.stock);
    }
    if (typeof req.body.price === 'string') {
      itemData.price = JSON.parse(req.body.price);
    }

    const item = await ShopItem.create(itemData);
    await item.populate('vendor', 'name phone location');

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Item created successfully',
      data: item,
    });
  } catch (error) {
    logger.error('Create item error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update shop item (Vendor only)
// @route   PUT /api/shop/items/:id
// @access  Private/Vendor
exports.updateItem = async (req, res) => {
  try {
    let item = await ShopItem.findById(req.params.id);

    if (!item) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Item not found',
      });
    }

    // Check ownership
    if (item.vendor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this item',
      });
    }

    // Handle image upload if new images are provided
    if (req.files && req.files.length > 0) {
      const imagePromises = req.files.map(async (file, index) => {
        const destination = `shop_products/${Date.now()}_${file.originalname}`;
        const url = await uploadToStorage(file, destination);
        return {
          url,
          isPrimary: index === 0,
          alt: file.originalname,
        };
      });
      req.body.images = await Promise.all(imagePromises);
    }

    item = await ShopItem.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    }).populate('vendor', 'name phone location');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Item updated successfully',
      data: item,
    });
  } catch (error) {
    logger.error('Update item error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Delete shop item (Vendor only)
// @route   DELETE /api/shop/items/:id
// @access  Private/Vendor
exports.deleteItem = async (req, res) => {
  try {
    const item = await ShopItem.findById(req.params.id);

    if (!item) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Item not found',
      });
    }

    // Check ownership
    if (item.vendor.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this item',
      });
    }

    // Soft delete
    item.isAvailable = false;
    await item.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Item deleted successfully',
    });
  } catch (error) {
    logger.error('Delete item error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete item',
    });
  }
};

// @desc    Add review to item
// @route   POST /api/shop/items/:id/review
// @access  Private
exports.addReview = async (req, res) => {
  try {
    const { rating, comment } = req.body;

    const item = await ShopItem.findById(req.params.id);

    if (!item) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Item not found',
      });
    }

    // Check if user already reviewed
    const alreadyReviewed = item.reviews.find(
      (r) => r.user.toString() === req.user.id
    );

    if (alreadyReviewed) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'You have already reviewed this item',
      });
    }

    const review = {
      user: req.user.id,
      rating: Number(rating),
      comment,
    };

    item.reviews.push(review);

    // Update ratings
    item.ratings.count = item.reviews.length;
    item.ratings.average =
      item.reviews.reduce((acc, r) => acc + r.rating, 0) / item.reviews.length;

    await item.save();

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Review added successfully',
      data: item,
    });
  } catch (error) {
    logger.error('Add review error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Get featured items
// @route   GET /api/shop/featured
// @access  Public
exports.getFeaturedItems = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const items = await ShopItem.find({ isFeatured: true, isAvailable: true })
      .populate('vendor', 'name location')
      .sort({ sales: -1 })
      .limit(limit);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: items,
    });
  } catch (error) {
    logger.error('Get featured items error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch featured items',
    });
  }
};

// ========== CART CONTROLLERS ==========

// @desc    Get user cart
// @route   GET /api/shop/cart
// @access  Private
exports.getCart = async (req, res) => {
  try {
    let cart = await Cart.findOne({ user: req.user.id }).populate(
      'items.product',
      'name price images stock'
    );

    if (!cart) {
      cart = await Cart.create({ user: req.user.id, items: [] });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    logger.error('Get cart error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch cart',
    });
  }
};

// @desc    Add item to cart
// @route   POST /api/shop/cart
// @access  Private
exports.addToCart = async (req, res) => {
  try {
    const { productId, quantity } = req.body;

    // Check if product exists and is available
    const product = await ShopItem.findById(productId);

    if (!product || !product.isAvailable) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Product not found or unavailable',
      });
    }

    // Check stock
    if (product.stock.quantity < quantity) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Insufficient stock',
      });
    }

    let cart = await Cart.findOne({ user: req.user.id });

    if (!cart) {
      cart = await Cart.create({
        user: req.user.id,
        items: [
          {
            product: productId,
            quantity,
            price: product.price.discounted || product.price.original,
          },
        ],
      });
    } else {
      // Check if item already exists in cart
      const itemIndex = cart.items.findIndex(
        (item) => item.product.toString() === productId
      );

      if (itemIndex > -1) {
        // Update quantity
        cart.items[itemIndex].quantity += quantity;
      } else {
        // Add new item
        cart.items.push({
          product: productId,
          quantity,
          price: product.price.discounted || product.price.original,
        });
      }

      await cart.save();
    }

    await cart.populate('items.product', 'name price images stock');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Item added to cart',
      data: cart,
    });
  } catch (error) {
    logger.error('Add to cart error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update cart item
// @route   PUT /api/shop/cart/:productId
// @access  Private
exports.updateCartItem = async (req, res) => {
  try {
    const { quantity } = req.body;

    const cart = await Cart.findOne({ user: req.user.id });

    if (!cart) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Cart not found',
      });
    }

    const itemIndex = cart.items.findIndex(
      (item) => item.product.toString() === req.params.productId
    );

    if (itemIndex === -1) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Item not found in cart',
      });
    }

    if (quantity <= 0) {
      // Remove item
      cart.items.splice(itemIndex, 1);
    } else {
      // Update quantity
      cart.items[itemIndex].quantity = quantity;
    }

    await cart.save();
    await cart.populate('items.product', 'name price images stock');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Cart updated successfully',
      data: cart,
    });
  } catch (error) {
    logger.error('Update cart item error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Remove item from cart
// @route   DELETE /api/shop/cart/:productId
// @access  Private
exports.removeFromCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });

    if (!cart) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Cart not found',
      });
    }

    cart.items = cart.items.filter(
      (item) => item.product.toString() !== req.params.productId
    );

    await cart.save();
    await cart.populate('items.product', 'name price images stock');

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Item removed from cart',
      data: cart,
    });
  } catch (error) {
    logger.error('Remove from cart error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to remove item from cart',
    });
  }
};

// @desc    Clear cart
// @route   DELETE /api/shop/cart
// @access  Private
exports.clearCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });

    if (!cart) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Cart not found',
      });
    }

    cart.items = [];
    await cart.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Cart cleared successfully',
      data: cart,
    });
  } catch (error) {
    logger.error('Clear cart error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to clear cart',
    });
  }
};

// ========== ORDER CONTROLLERS ==========

// @desc    Create order
// @route   POST /api/shop/orders
// @access  Private
exports.createOrder = async (req, res) => {
  try {
    const { items, shippingAddress, paymentMethod, notes } = req.body;

    if (!items || items.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No order items provided',
      });
    }

    // Calculate total and prepare order items
    let totalAmount = 0;
    const orderItems = [];

    for (const item of items) {
      const product = await ShopItem.findById(item.product);

      if (!product || !product.isAvailable) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: `Product ${product?.name || item.product} is not available`,
        });
      }

      if (product.stock.quantity < item.quantity) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: `Insufficient stock for ${product.name}`,
        });
      }

      const price = product.price.discounted || product.price.original;
      const subtotal = price * item.quantity;

      orderItems.push({
        product: product._id,
        name: product.name,
        quantity: item.quantity,
        unit: product.stock.unit,
        price,
        subtotal,
      });

      totalAmount += subtotal;

      // Update product stock and sales
      product.stock.quantity -= item.quantity;
      product.sales += item.quantity;
      await product.save({ validateBeforeSave: false });
    }

    // Create order
    const order = await Order.create({
      user: req.user.id,
      items: orderItems,
      totalAmount,
      shippingAddress,
      paymentMethod,
      notes,
      statusHistory: [
        {
          status: 'pending',
          timestamp: Date.now(),
        },
      ],
    });

    // Clear cart after order
    await Cart.findOneAndUpdate({ user: req.user.id }, { items: [] });

    await order.populate('items.product', 'name images');

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Order placed successfully',
      data: order,
    });
  } catch (error) {
    logger.error('Create order error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Get user orders
// @route   GET /api/shop/orders
// @access  Private
exports.getUserOrders = async (req, res) => {
  try {
    const { status } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { user: req.user.id };
    if (status) query.status = status;

    const orders = await Order.find(query)
      .populate('items.product', 'name images')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Order.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: orders,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get user orders error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch orders',
    });
  }
};

// @desc    Get order by ID
// @route   GET /api/shop/orders/:id
// @access  Private
exports.getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate(
      'items.product',
      'name images vendor'
    );

    if (!order) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Order not found',
      });
    }

    // Check ownership
    if (order.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this order',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: order,
    });
  } catch (error) {
    logger.error('Get order by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch order',
    });
  }
};

// @desc    Cancel order
// @route   PUT /api/shop/orders/:id/cancel
// @access  Private
exports.cancelOrder = async (req, res) => {
  try {
    const { reason } = req.body;

    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Order not found',
      });
    }

    // Check ownership
    if (order.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to cancel this order',
      });
    }

    // Check if order can be cancelled
    if (['shipped', 'delivered', 'cancelled'].includes(order.status)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: `Cannot cancel order with status: ${order.status}`,
      });
    }

    // Restore product stock
    for (const item of order.items) {
      await ShopItem.findByIdAndUpdate(item.product, {
        $inc: {
          'stock.quantity': item.quantity,
          sales: -item.quantity,
        },
      });
    }

    order.status = 'cancelled';
    order.cancellation = {
      reason,
      cancelledBy: req.user.id,
      cancelledAt: Date.now(),
    };
    order.statusHistory.push({
      status: 'cancelled',
      timestamp: Date.now(),
      note: reason,
    });

    await order.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order cancelled successfully',
      data: order,
    });
  } catch (error) {
    logger.error('Cancel order error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to cancel order',
    });
  }
};

// @desc    Update order status (Admin/Vendor only)
// @route   PUT /api/shop/orders/:id/status
// @access  Private/Admin/Vendor
exports.updateOrderStatus = async (req, res) => {
  try {
    const { status, note } = req.body;

    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Order not found',
      });
    }

    order.status = status;
    order.statusHistory.push({
      status,
      timestamp: Date.now(),
      note,
    });

    if (status === 'shipped' && req.body.shippingDetails) {
      order.shippingDetails = req.body.shippingDetails;
    }

    if (status === 'delivered') {
      order.shippingDetails.deliveredAt = Date.now();
    }

    await order.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order status updated successfully',
      data: order,
    });
  } catch (error) {
    logger.error('Update order status error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};
