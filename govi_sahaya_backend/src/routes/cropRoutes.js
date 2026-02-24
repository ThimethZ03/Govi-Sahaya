const express = require('express');
const router = express.Router();
const Crop = require('../models/Crop');
const { optionalAuth } = require('../middleware/authMiddleware');

// Get all crops
router.get('/', optionalAuth, async (req, res) => {
  try {
    const crops = await Crop.find().select('-__v');
    
    res.status(200).json({
      success: true,
      count: crops.length,
      data: crops,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching crops',
      error: error.message,
    });
  }
});

// Get single crop by ID
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const crop = await Crop.findById(req.params.id);
    
    if (!crop) {
      return res.status(404).json({
        success: false,
        message: 'Crop not found',
      });
    }
    
    res.status(200).json({
      success: true,
      data: crop,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching crop',
      error: error.message,
    });
  }
});

module.exports = router;
