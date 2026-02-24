const express = require('express');
const router = express.Router();
const Disease = require('../models/Disease');
const { optionalAuth } = require('../middleware/authMiddleware');

// Get all diseases
router.get('/', optionalAuth, async (req, res) => {
  try {
    const diseases = await Disease.find().select('-__v');
    
    res.status(200).json({
      success: true,
      count: diseases.length,
      data: diseases,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching diseases',
      error: error.message,
    });
  }
});

// Get diseases by crop
router.get('/crop/:cropName', optionalAuth, async (req, res) => {
  try {
    const diseases = await Disease.find({ 
      cropName: new RegExp(req.params.cropName, 'i') 
    });
    
    res.status(200).json({
      success: true,
      count: diseases.length,
      data: diseases,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching diseases',
      error: error.message,
    });
  }
});

// Get single disease by ID
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const disease = await Disease.findById(req.params.id);
    
    if (!disease) {
      return res.status(404).json({
        success: false,
        message: 'Disease not found',
      });
    }
    
    res.status(200).json({
      success: true,
      data: disease,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching disease',
      error: error.message,
    });
  }
});

module.exports = router;
