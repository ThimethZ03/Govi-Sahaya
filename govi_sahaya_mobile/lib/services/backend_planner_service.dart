import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackendPlannerService {
  static const String baseUrl = 'http://192.168.8.136:5000/api/v1/planner';
  final NotificationService _notificationService = NotificationService();

  // Get auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  // ✅ CHECK BUDGET AND TRIGGER NOTIFICATION
  Future<void> checkBudgetAlert(String fieldId) async {
    try {
      final fieldData = await getFieldById(fieldId);

      final String fieldName = fieldData['name'] ?? 'Field';
      final double budget = (fieldData['budget'] ?? 0).toDouble();
      final double spent = (fieldData['totalSpent'] ?? 0).toDouble();

      await _notificationService.checkBudgetAndNotify(
        fieldId: fieldId,
        fieldName: fieldName,
        budget: budget,
        spent: spent,
      );
    } catch (e) {
      print('❌ Error checking budget alert: $e');
    }
  }

  // ============================================
  // EXPENSE METHODS
  // ============================================

  // Get all expenses
  Future<Map<String, dynamic>> getAllExpenses({
    String? fieldId,
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (fieldId != null) 'field': fieldId,
        if (category != null) 'category': category,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri =
          Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get expenses response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get expenses error: $e');
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  // Create expense - ✅ WITH BUDGET ALERT
  Future<Map<String, dynamic>> createExpense(
      Map<String, dynamic> expenseData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expenseData),
      );

      print('📡 Create expense response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Expense created successfully');

        // ✅ CHECK BUDGET ALERT AFTER CREATING EXPENSE
        final fieldId = expenseData['field'];
        if (fieldId != null) {
          await checkBudgetAlert(fieldId);
        }

        return data;
      } else {
        throw Exception('Failed to create expense: ${response.body}');
      }
    } catch (e) {
      print('❌ Create expense error: $e');
      throw Exception('Failed to create expense: $e');
    }
  }

  // Update expense - ✅ WITH BUDGET ALERT
  Future<Map<String, dynamic>> updateExpense(
      String expenseId, Map<String, dynamic> expenseData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expenseData),
      );

      print('📡 Update expense response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Expense updated successfully');

        // ✅ CHECK BUDGET ALERT AFTER UPDATING EXPENSE
        final fieldId = expenseData['field'];
        if (fieldId != null) {
          await checkBudgetAlert(fieldId);
        }

        return data;
      } else {
        throw Exception('Failed to update expense: ${response.body}');
      }
    } catch (e) {
      print('❌ Update expense error: $e');
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete expense - ✅ WITH BUDGET ALERT
  Future<void> deleteExpense(String expenseId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete expense response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Expense deleted successfully');
        // Note: You may want to check budget alert for the field after deletion
      } else {
        throw Exception('Failed to delete expense: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Delete expense error: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get expense stats
  Future<Map<String, dynamic>> getExpenseStats({
    String? fieldId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        if (fieldId != null) 'field': fieldId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse('$baseUrl/expenses/stats')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get expense stats response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get expense stats error: $e');
      throw Exception('Failed to fetch expense stats: $e');
    }
  }

  // ============================================
  // FIELD METHODS
  // ============================================

  // Get all fields
  Future<List<dynamic>> getAllFields({bool? isActive}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        if (isActive != null) 'isActive': isActive.toString(),
      };

      final uri =
          Uri.parse('$baseUrl/fields').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get fields response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load fields: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get fields error: $e');
      throw Exception('Failed to fetch fields: $e');
    }
  }

  // Get field by ID
  Future<Map<String, dynamic>> getFieldById(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get field by ID response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load field: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get field by ID error: $e');
      throw Exception('Failed to fetch field: $e');
    }
  }

  // Create field
  Future<Map<String, dynamic>> createField(
      Map<String, dynamic> fieldData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/fields'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(fieldData),
      );

      print('📡 Create field response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Field created successfully');
        return data;
      } else {
        throw Exception('Failed to create field: ${response.body}');
      }
    } catch (e) {
      print('❌ Create field error: $e');
      throw Exception('Failed to create field: $e');
    }
  }

  // Update field - ✅ CLEAR NOTIFICATION FLAGS ON BUDGET UPDATE
  Future<Map<String, dynamic>> updateField(
      String fieldId, Map<String, dynamic> fieldData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/fields/$fieldId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(fieldData),
      );

      print('📡 Update field response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Field updated successfully');

        // ✅ CLEAR NOTIFICATION FLAGS IF BUDGET WAS UPDATED
        if (fieldData.containsKey('budget')) {
          await _notificationService.clearNotificationFlags(fieldId);
        }

        return data;
      } else {
        throw Exception('Failed to update field: ${response.body}');
      }
    } catch (e) {
      print('❌ Update field error: $e');
      throw Exception('Failed to update field: $e');
    }
  }

  // ✅ Delete field (will cascade delete expenses)
  Future<void> deleteField(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/fields/$fieldId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete field response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Field deleted successfully (with cascade)');

        // ✅ CLEAR NOTIFICATION FLAGS FOR DELETED FIELD
        await _notificationService.clearNotificationFlags(fieldId);
      } else {
        throw Exception('Failed to delete field: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Delete field error: $e');
      throw Exception('Failed to delete field: $e');
    }
  }

  // Get field expenses
  Future<Map<String, dynamic>> getFieldExpenses(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/fields/$fieldId/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get field expenses response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load field expenses: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get field expenses error: $e');
      throw Exception('Failed to fetch field expenses: $e');
    }
  }

  // ============================================
  // REPORT METHODS
  // ============================================

  // Generate profit report
  Future<Map<String, dynamic>> generateReport({
    required String startDate,
    required String endDate,
    String? fieldId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        if (fieldId != null) 'field': fieldId,
      };

      final uri =
          Uri.parse('$baseUrl/reports').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Generate report response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Generate report error: $e');
      throw Exception('Failed to generate report: $e');
    }
  }
}
