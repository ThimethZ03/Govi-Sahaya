import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';

class ProfitPlannerService {
  /// Change this to your backend IP
  static const String baseUrl = "http://52.77.220.23:5000s/api/v1/planner";

  /// Auth token (should come from login provider)
  String? token;

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token"
      };

  // ==============================
  // GET ALL EXPENSES
  // ==============================
  Future<List<ExpenseModel>> getExpenses() async {
    final response = await http.get(
      Uri.parse("$baseUrl/expenses"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List list = data['data'];

      return list.map((e) => ExpenseModel.fromJson(e)).toList();
    }

    throw Exception("Failed to load expenses");
  }

  // ==============================
  // ADD EXPENSE
  // ==============================
  Future<void> addExpense(ExpenseModel expense) async {
    final response = await http.post(
      Uri.parse("$baseUrl/expenses"),
      headers: headers,
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create expense");
    }
  }

  // ==============================
  // UPDATE EXPENSE
  // ==============================
  Future<void> updateExpense(ExpenseModel expense) async {
    final response = await http.put(
      Uri.parse("$baseUrl/expenses/${expense.id}"),
      headers: headers,
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update expense");
    }
  }

  // ==============================
  // DELETE EXPENSE
  // ==============================
  Future<void> deleteExpense(String expenseId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/expenses/$expenseId"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete expense");
    }
  }

  // ==============================
  // GET EXPENSE STATS
  // ==============================
  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/expenses/stats"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return data['data'];
    }

    throw Exception("Failed to load stats");
  }
}
