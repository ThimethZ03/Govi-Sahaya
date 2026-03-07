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

// All routes are protected
router.use(protect);

// ============================================
// EXPENSE ROUTES
// ============================================
router.get('/expenses/stats', getExpenseStats); // ⚠️ Must be before /expenses/:id
router.get('/expenses', getAllExpenses);
router.get('/expenses/:id', getExpenseById);
router.post('/expenses', createExpense);
router.put('/expenses/:id', updateExpense);
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
