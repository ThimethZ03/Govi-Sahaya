// routes/safetyAssistRoutes.js

const express = require('express');
const router = express.Router();
const {
  getEmergencyContacts,
  getFirstAidGuides,
  getFirstAidGuideById,
  getSafetyTips,
  getNearbyHospitals,
} = require('../controllers/safetyAssistController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/emergency-contacts', getEmergencyContacts);
router.get('/first-aid',          getFirstAidGuides);
router.get('/first-aid/:id',      getFirstAidGuideById);
router.get('/tips',               getSafetyTips);
router.get('/nearby-hospitals',   getNearbyHospitals);

module.exports = router;
