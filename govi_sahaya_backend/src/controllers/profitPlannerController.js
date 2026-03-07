const Expense = require('../models/Expense');
const Field = require('../models/Field');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');
const mongoose = require('mongoose');
const notificationService = require('../services/notificationService');

// ── Notification helper (non-blocking) ───────────────────────────────────────
async function sendPlannerNotification(userId, title, message, priority = 'medium', data = {}) {
  try {
    await notificationService.createNotification(userId, {
      type:    'general',
      title,
      message,
      priority,
      data,
      sendVia: { push: true, email: false, sms: false },
    });
    logger.info(`📢 Planner notification → user ${userId}: "${title}"`);
  } catch (e) {
    logger.error('sendPlannerNotification error:', e.message);
    // Non-critical — never block the main response
  }
}

// ── Budget check helper ───────────────────────────────────────────────────────
// Called after any expense create/update/delete that affects a field budget
async function checkBudgetAndNotify(fieldId, userId) {
  try {
    const field = await Field.findById(fieldId);
    if (!field || !field.budget || field.budget <= 0) return;

    const result = await Expense.aggregate([
      {
        $match: {
          field: new mongoose.Types.ObjectId(fieldId),
          user:  new mongoose.Types.ObjectId(userId),
        },
      },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);

    const totalSpent  = result[0]?.total ?? 0;
    const budget      = field.budget;
    const remaining   = budget - totalSpent;
    const percentage  = Math.round((totalSpent / budget) * 100);

    const notifData = {
      fieldId:    field._id,
      fieldName:  field.name,
      percentage,
      totalSpent,
      budget,
      remaining,
    };

    if (percentage >= 100) {
      // ── Over budget ───────────────────────────────────────────────
      await sendPlannerNotification(
        userId,
        '🚨 Budget Exceeded',
        `"${field.name}" is over budget by LKR ${Math.abs(remaining).toLocaleString()}. Total spent: LKR ${totalSpent.toLocaleString()} / LKR ${budget.toLocaleString()}.`,
        'urgent',
        notifData
      );
    } else if (percentage >= 80) {
      // ── 80% warning ───────────────────────────────────────────────
      await sendPlannerNotification(
        userId,
        '⚠️ Budget Warning',
        `You've used ${percentage}% of the budget for "${field.name}". LKR ${remaining.toLocaleString()} remaining.`,
        'high',
        notifData
      );
    }

    logger.info(
      `💰 Budget check → "${field.name}": ${percentage}% used (LKR ${totalSpent}/${budget})`
    );
  } catch (e) {
    logger.error('checkBudgetAndNotify error:', e.message);
  }
}

// ============================================
// EXPENSE CONTROLLERS
// ============================================

// @desc    Get all expenses
// @route   GET /api/v1/planner/expenses
// @access  Private
exports.getAllExpenses = async (req, res) => {
  try {
    const { category, field, startDate, endDate } = req.query;
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const query = { user: req.user.id };
    if (category) query.category = category;
    if (field)    query.field    = field;
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate)   query.date.$lte = new Date(endDate);
    }

    const expenses = await Expense.find(query)
      .populate('field', 'name area')
      .sort({ date: -1 })
      .limit(limit)
      .skip(skip);

    const total = await Expense.countDocuments(query);

    logger.info(`Fetched ${expenses.length} expenses for user ${req.user.id}`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: expenses,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all expenses error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch expenses',
      error: error.message,
    });
  }
};

// @desc    Get expense by ID
// @route   GET /api/v1/planner/expenses/:id
// @access  Private
exports.getExpenseById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid expense ID',
      });
    }

    const expense = await Expense.findById(req.params.id).populate('field', 'name area');

    if (!expense) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Expense not found',
      });
    }

    if (expense.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this expense',
      });
    }

    res.status(HTTP_STATUS.OK).json({ success: true, data: expense });
  } catch (error) {
    logger.error('Get expense by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch expense',
      error: error.message,
    });
  }
};

// @desc    Create expense
// @route   POST /api/v1/planner/expenses
// @access  Private
exports.createExpense = async (req, res) => {
  try {
    const expenseData = { ...req.body, user: req.user.id };

    // Validate field ownership
    if (expenseData.field) {
      const field = await Field.findOne({
        _id:  expenseData.field,
        user: req.user.id,
      });
      if (!field) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Invalid field ID or field does not belong to you',
        });
      }
    }

    const expense = await Expense.create(expenseData);
    await expense.populate('field', 'name area');

    logger.info(`Expense created: ${expense._id} by user ${req.user.id}`);

    // ✅ Check budget after adding expense
    if (expense.field) {
      await checkBudgetAndNotify(expense.field._id ?? expense.field, req.user.id);
    }

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Expense created successfully',
      data: expense,
    });
  } catch (error) {
    logger.error('Create expense error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update expense
// @route   PUT /api/v1/planner/expenses/:id
// @access  Private
exports.updateExpense = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid expense ID',
      });
    }

    let expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Expense not found',
      });
    }

    if (expense.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this expense',
      });
    }

    // Validate new field if being changed
    if (req.body.field) {
      const field = await Field.findOne({
        _id:  req.body.field,
        user: req.user.id,
      });
      if (!field) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Invalid field ID or field does not belong to you',
        });
      }
    }

    // ✅ Store old field before update (amount change may affect old field budget)
    const oldFieldId = expense.field;

    expense = await Expense.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    }).populate('field', 'name area');

    logger.info(`Expense updated: ${expense._id} by user ${req.user.id}`);

    // ✅ Re-check budget on both old and new field after update
    const newFieldId = expense.field?._id ?? expense.field;
    if (newFieldId) {
      await checkBudgetAndNotify(newFieldId, req.user.id);
    }
    if (oldFieldId && oldFieldId.toString() !== newFieldId?.toString()) {
      await checkBudgetAndNotify(oldFieldId, req.user.id);
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Expense updated successfully',
      data: expense,
    });
  } catch (error) {
    logger.error('Update expense error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Delete expense
// @route   DELETE /api/v1/planner/expenses/:id
// @access  Private
exports.deleteExpense = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid expense ID',
      });
    }

    const expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Expense not found',
      });
    }

    if (expense.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this expense',
      });
    }

    // ✅ Store field before deletion for budget recheck
    const affectedFieldId = expense.field;

    await expense.deleteOne();

    logger.info(`Expense deleted: ${req.params.id} by user ${req.user.id}`);

    // ✅ Re-check budget after deletion (may have dropped below threshold)
    if (affectedFieldId) {
      await checkBudgetAndNotify(affectedFieldId, req.user.id);
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Expense deleted successfully',
    });
  } catch (error) {
    logger.error('Delete expense error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete expense',
      error: error.message,
    });
  }
};

// @desc    Get expense statistics
// @route   GET /api/v1/planner/expenses/stats
// @access  Private
exports.getExpenseStats = async (req, res) => {
  try {
    const { startDate, endDate, field } = req.query;
    const userId = new mongoose.Types.ObjectId(req.user.id);

    const matchQuery = { user: userId };

    if (field && mongoose.Types.ObjectId.isValid(field)) {
      matchQuery.field = new mongoose.Types.ObjectId(field);
    }
    if (startDate || endDate) {
      matchQuery.date = {};
      if (startDate) matchQuery.date.$gte = new Date(startDate);
      if (endDate)   matchQuery.date.$lte = new Date(endDate);
    }

    const totalExpenses = await Expense.aggregate([
      { $match: matchQuery },
      { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } },
    ]);

    const categoryBreakdown = await Expense.aggregate([
      { $match: matchQuery },
      { $group: { _id: '$category', total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { total: -1 } },
    ]);

    const sixMonthsAgo      = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const monthlyMatchQuery = { ...matchQuery };
    if (!monthlyMatchQuery.date) {
      monthlyMatchQuery.date = { $gte: sixMonthsAgo };
    }

    const monthlyTrend = await Expense.aggregate([
      { $match: monthlyMatchQuery },
      {
        $group: {
          _id:   { year: { $year: '$date' }, month: { $month: '$date' } },
          total: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    logger.info(`Fetched expense stats for user ${req.user.id}`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: {
        total: totalExpenses[0]?.total || 0,
        count: totalExpenses[0]?.count || 0,
        categoryBreakdown,
        monthlyTrend,
      },
    });
  } catch (error) {
    logger.error('Get expense stats error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch expense statistics',
      error: error.message,
    });
  }
};

// ============================================
// FIELD CONTROLLERS
// ============================================

// @desc    Get all fields
// @route   GET /api/v1/planner/fields
// @access  Private
exports.getAllFields = async (req, res) => {
  try {
    const { isActive } = req.query;
    const query = { user: req.user.id };
    if (isActive !== undefined) query.isActive = isActive === 'true';

    const fields = await Field.find(query).sort({ createdAt: -1 });

    const fieldsWithStats = await Promise.all(
      fields.map(async (field) => {
        const expenses   = await Expense.find({ field: field._id });
        const totalSpent = expenses.reduce((sum, exp) => sum + exp.amount, 0);

        let areaDisplay = 'N/A';
        if (field.area?.value) {
          const unitLabels = {
            acres:          'Acres',
            hectares:       'Hectares',
            perches:        'Perches',
            square_meters:  'Sq.m',
          };
          areaDisplay = `${field.area.value} ${unitLabels[field.area.unit] || field.area.unit}`;
        }

        const budget         = field.budget || 0;
        const remaining      = budget - totalSpent;
        const percentageUsed = budget > 0 ? Math.round((totalSpent / budget) * 100) : 0;

        return {
          ...field.toObject(),
          totalSpent,
          expenseCount: expenses.length,
          areaDisplay,
          budget,
          remaining,
          percentageUsed,
        };
      })
    );

    logger.info(`Fetched ${fieldsWithStats.length} fields for user ${req.user.id}`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: fieldsWithStats,
      count: fieldsWithStats.length,
    });
  } catch (error) {
    logger.error('Get all fields error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch fields',
      error: error.message,
    });
  }
};

// @desc    Get field by ID
// @route   GET /api/v1/planner/fields/:id
// @access  Private
exports.getFieldById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid field ID',
      });
    }

    const field = await Field.findById(req.params.id);

    if (!field) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Field not found',
      });
    }

    if (field.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this field',
      });
    }

    const expenses   = await Expense.find({ field: field._id }).sort({ date: -1 });
    const totalSpent = expenses.reduce((sum, exp) => sum + exp.amount, 0);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: { ...field.toObject(), totalSpent, expenses },
    });
  } catch (error) {
    logger.error('Get field by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch field',
      error: error.message,
    });
  }
};

// @desc    Create field
// @route   POST /api/v1/planner/fields
// @access  Private
exports.createField = async (req, res) => {
  try {
    const field = await Field.create({ ...req.body, user: req.user.id });

    logger.info(`Field created: ${field._id} by user ${req.user.id}`);

    // ✅ Notify field created
    await sendPlannerNotification(
      req.user.id,
      '🌾 New Field Added',
      `"${field.name}" has been added to your profit planner${
        field.budget > 0
          ? ` with a budget of LKR ${field.budget.toLocaleString()}`
          : ''
      }.`,
      'low',
      { fieldId: field._id, fieldName: field.name, budget: field.budget }
    );

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Field created successfully',
      data: field,
    });
  } catch (error) {
    logger.error('Create field error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update field
// @route   PUT /api/v1/planner/fields/:id
// @access  Private
exports.updateField = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid field ID',
      });
    }

    const oldField = await Field.findById(req.params.id);

    if (!oldField) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Field not found',
      });
    }

    if (oldField.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this field',
      });
    }

    const field = await Field.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    logger.info(`Field updated: ${field._id} by user ${req.user.id}`);

    // ✅ Notify if budget changed
    if (
      req.body.budget !== undefined &&
      Number(req.body.budget) !== Number(oldField.budget)
    ) {
      await sendPlannerNotification(
        req.user.id,
        '💰 Budget Updated',
        `Budget for "${field.name}" updated from LKR ${oldField.budget.toLocaleString()} to LKR ${Number(req.body.budget).toLocaleString()}.`,
        'low',
        { fieldId: field._id, fieldName: field.name, oldBudget: oldField.budget, newBudget: req.body.budget }
      );

      // ✅ Re-run budget threshold check with new budget
      await checkBudgetAndNotify(field._id, req.user.id);
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Field updated successfully',
      data: field,
    });
  } catch (error) {
    logger.error('Update field error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Delete field (hard delete with cascade)
// @route   DELETE /api/v1/planner/fields/:id
// @access  Private
exports.deleteField = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid field ID',
      });
    }

    const field = await Field.findById(req.params.id);

    if (!field) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Field not found',
      });
    }

    if (field.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this field',
      });
    }

    // ✅ Store name before deletion for notification message
    const fieldName     = field.name;
    const expenseCount  = await Expense.countDocuments({ field: field._id });

    // Hard delete — triggers cascade middleware in Field model
    await field.deleteOne();

    logger.info(`Field hard deleted: ${req.params.id} by user ${req.user.id}`);

    // ✅ Notify field deleted
    await sendPlannerNotification(
      req.user.id,
      '🗑️ Field Deleted',
      `"${fieldName}" and ${expenseCount} related expense${expenseCount !== 1 ? 's' : ''} have been permanently deleted.`,
      'low',
      { fieldName, expenseCount }
    );

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Field and related expenses deleted successfully',
    });
  } catch (error) {
    logger.error('Delete field error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete field',
      error: error.message,
    });
  }
};

// @desc    Get field expenses
// @route   GET /api/v1/planner/fields/:id/expenses
// @access  Private
exports.getFieldExpenses = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid field ID',
      });
    }

    const field = await Field.findById(req.params.id);

    if (!field) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Field not found',
      });
    }

    if (field.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this field',
      });
    }

    const expenses = await Expense.find({ field: req.params.id })
      .sort({ date: -1 })
      .limit(100);

    const totalExpenses = await Expense.aggregate([
      { $match: { field: new mongoose.Types.ObjectId(req.params.id) } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: expenses,
      totalExpenses: totalExpenses[0]?.total || 0,
      count: expenses.length,
    });
  } catch (error) {
    logger.error('Get field expenses error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch field expenses',
      error: error.message,
    });
  }
};

// ============================================
// REPORT CONTROLLER
// ============================================

// @desc    Generate profit report
// @route   GET /api/v1/planner/reports
// @access  Private
exports.generateReport = async (req, res) => {
  try {
    const { startDate, endDate, field } = req.query;
    const userId = new mongoose.Types.ObjectId(req.user.id);

    if (!startDate || !endDate) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Start date and end date are required',
      });
    }

    const matchQuery = {
      user: userId,
      date: { $gte: new Date(startDate), $lte: new Date(endDate) },
    };

    if (field && mongoose.Types.ObjectId.isValid(field)) {
      matchQuery.field = new mongoose.Types.ObjectId(field);
    }

    const expenses = await Expense.find(matchQuery)
      .populate('field', 'name area')
      .sort({ date: -1 });

    const summary = await Expense.aggregate([
      { $match: matchQuery },
      { $group: { _id: '$category', total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { total: -1 } },
    ]);

    const grandTotal = summary.reduce((sum, item) => sum + item.total, 0);

    logger.info(`Report generated for user ${req.user.id}: ${startDate} to ${endDate}`);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: {
        period: { startDate, endDate },
        grandTotal,
        summary,
        expenses,
        totalExpenses: expenses.length,
      },
    });
  } catch (error) {
    logger.error('Generate report error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to generate report',
      error: error.message,
    });
  }
};
