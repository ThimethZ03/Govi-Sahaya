const express = require('express');
const router = express.Router();

const {
  // Expense controllers
  getAllExpenses,
  getExpenseById,
  createExpense,
  updateExpense,
  deleteExpense,
  getExpenseStats,

  // Field controllers
  getAllFields,
  getFieldById,
  createField,
  updateField,
  deleteField,
  getFieldExpenses,

  // Report controller
  generateReport,
} = require('../controllers/profitPlannerController');

const { protect } = require('../middleware/authMiddleware');

// ✅ FIXED: use uploadReceiptOptional for both create and update
const { uploadReceiptOptional } = require('../middleware/uploadMiddleware');

// ============================================
// All routes protected
// ============================================
router.use(protect);

// ============================================
// EXPENSE ROUTES
// ============================================

// ⚠️ must be before /expenses/:id
router.get('/expenses/stats', getExpenseStats);

// Get all expenses
router.get('/expenses', getAllExpenses);

// Get single expense
router.get('/expenses/:id', getExpenseById);

// ✅ FIXED: uploadReceiptOptional — works with OR without a receipt file
router.post(
  '/expenses',
  uploadReceiptOptional('receipt'),
  createExpense
);

// ✅ FIXED: uploadReceiptOptional — works with OR without a receipt file
router.put(
  '/expenses/:id',
  uploadReceiptOptional('receipt'),
  updateExpense
);

// Delete expense
router.delete('/expenses/:id', deleteExpense);

// ============================================
// FIELD ROUTES
// ============================================

router.get('/fields', getAllFields);

router.get('/fields/:id', getFieldById);

router.post('/fields', createField);

router.put('/fields/:id', updateField);

router.delete('/fields/:id', deleteField);

router.get('/fields/:id/expenses', getFieldExpenses);

// ============================================
// REPORT ROUTES
// ============================================

router.get('/reports', generateReport);

module.exports = router;
