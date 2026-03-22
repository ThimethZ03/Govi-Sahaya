import '../models/expense_model.dart';

class ProfitPlannerService {
  Future<List<FieldBudget>> getFieldBudgets() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    return [
      FieldBudget(
        id: '1',
        name: 'Field 1',
        totalEstimated: 200000,
        totalSpent: 150000,
        expenses: [
          ExpenseModel(
            id: '1',
            fieldId: '1',
            category: 'Fertilizer',
            description: 'Organic fertilizer',
            estimatedCost: 30000,
            spentAmount: 28000,
            date: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ExpenseModel(
            id: '2',
            fieldId: '1',
            category: 'Water',
            description: 'Irrigation',
            estimatedCost: 40000,
            spentAmount: 42000,
            date: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ],
      ),
      FieldBudget(
        id: '2',
        name: 'Field 2',
        totalEstimated: 150000,
        totalSpent: 120000,
        expenses: [],
      ),
    ];
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Save to backend or local storage
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Update in backend or local storage
  }

  Future<void> deleteExpense(String expenseId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Delete from backend or local storage
  }
}
