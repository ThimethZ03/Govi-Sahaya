import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ add
import 'package:mime/mime.dart'; // ✅ add
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import '../core/network/api_endpoints.dart';

class BackendPlannerService {
  final NotificationService _notificationService = NotificationService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  // ── Budget alert ──────────────────────────────────────────────────
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

  // ============================================================
  // EXPENSE METHODS
  // ============================================================

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

      final uri = Uri.parse(ApiEndpoints.profitExpenses)
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get expenses response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get expenses error: $e');
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  // ── Create expense ────────────────────────────────────────────
  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> expenseData, {
    File? receiptFile,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.profitExpenses),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Flat scalar fields
      expenseData.forEach((key, value) {
        if (value != null && key != 'quantity' && key != 'recurring') {
          if (key == 'field') {
            request.fields[key] = value.toString().replaceAll('"', '');
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Quantity → bracket notation
      final qty = expenseData['quantity'];
      if (qty is Map) {
        if (qty['value'] != null) {
          request.fields['quantity[value]'] = qty['value'].toString();
        }
        if (qty['unit'] != null) {
          request.fields['quantity[unit]'] = qty['unit'].toString();
        }
      }

      // Recurring → bracket notation
      final rec = expenseData['recurring'];
      if (rec is Map) {
        if (rec['interval'] != null) {
          request.fields['recurring[interval]'] = rec['interval'].toString();
        }
        if (rec['unit'] != null) {
          request.fields['recurring[unit]'] = rec['unit'].toString();
        }
      }

      // ✅ Attach receipt file with explicit MIME type
      if (receiptFile != null) {
        final fileName = receiptFile.path.split('/').last;
        final mimeType = lookupMimeType(receiptFile.path) ?? 'image/jpeg';
        final parts = mimeType.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'receipt',
            receiptFile.path,
            filename: fileName,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      print('📤 Sending expense fields: ${request.fields}');
      print('📤 Receipt file: ${receiptFile?.path ?? 'none'}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Create expense response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        final fieldId = expenseData['field'];
        if (fieldId != null) {
          await checkBudgetAlert(fieldId.toString().replaceAll('"', ''));
        }

        return data;
      } else {
        String errorMsg = 'Failed to create expense (${response.statusCode})';
        try {
          final errorBody = json.decode(response.body);
          errorMsg = errorBody['message'] ?? errorBody['error'] ?? errorMsg;
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Update expense ────────────────────────────────────────────
  Future<Map<String, dynamic>> updateExpense(
    String expenseId,
    Map<String, dynamic> expenseData, {
    File? receiptFile,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiEndpoints.profitExpenses}/$expenseId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Flat scalar fields (skip nested maps + existingReceiptUrl)
      expenseData.forEach((key, value) {
        if (value != null &&
            key != 'quantity' &&
            key != 'recurring' &&
            key != 'existingReceiptUrl') {
          if (key == 'field') {
            request.fields[key] = value.toString().replaceAll('"', '');
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Quantity → bracket notation
      final qty = expenseData['quantity'];
      if (qty is Map) {
        if (qty['value'] != null) {
          request.fields['quantity[value]'] = qty['value'].toString();
        }
        if (qty['unit'] != null) {
          request.fields['quantity[unit]'] = qty['unit'].toString();
        }
      }

      // Recurring → bracket notation
      final rec = expenseData['recurring'];
      if (rec is Map) {
        if (rec['interval'] != null) {
          request.fields['recurring[interval]'] = rec['interval'].toString();
        }
        if (rec['unit'] != null) {
          request.fields['recurring[unit]'] = rec['unit'].toString();
        }
      }

      // Preserve existing Cloudinary URL when no new file picked
      final existingReceiptUrl = expenseData['existingReceiptUrl'];
      if (existingReceiptUrl != null && receiptFile == null) {
        request.fields['receiptUrl'] = existingReceiptUrl.toString();
      }

      // ✅ Attach new receipt file with explicit MIME type
      if (receiptFile != null) {
        final fileName = receiptFile.path.split('/').last;
        final mimeType = lookupMimeType(receiptFile.path) ?? 'image/jpeg';
        final parts = mimeType.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'receipt',
            receiptFile.path,
            filename: fileName,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      print('📤 Updating expense fields: ${request.fields}');
      print('📤 Receipt file: ${receiptFile?.path ?? 'none'}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Update expense response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final fieldId = expenseData['field']?.toString().replaceAll('"', '');
        if (fieldId != null && fieldId.isNotEmpty) {
          await checkBudgetAlert(fieldId);
        }

        return data;
      } else {
        String errorMsg = 'Failed to update expense (${response.statusCode})';
        try {
          final errorBody = json.decode(response.body);
          errorMsg = errorBody['message'] ?? errorBody['error'] ?? errorMsg;
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Delete expense ────────────────────────────────────────────
  Future<void> deleteExpense(String expenseId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.profitExpenses}/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete expense response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Expense deleted successfully');
      } else {
        throw Exception('Failed to delete expense: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Delete expense error: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ── Expense stats ─────────────────────────────────────────────
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

      final uri = Uri.parse('${ApiEndpoints.profitExpenses}/stats')
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

  // ============================================================
  // FIELD METHODS
  // ============================================================

  Future<List<dynamic>> getAllFields({bool? isActive}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        if (isActive != null) 'isActive': isActive.toString(),
      };

      final uri = Uri.parse(ApiEndpoints.profitFields)
          .replace(queryParameters: queryParams);

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

  Future<Map<String, dynamic>> getFieldById(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.profitFields}/$fieldId'),
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

  Future<Map<String, dynamic>> createField(
      Map<String, dynamic> fieldData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(ApiEndpoints.profitFields),
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

  Future<Map<String, dynamic>> updateField(
      String fieldId, Map<String, dynamic> fieldData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${ApiEndpoints.profitFields}/$fieldId'),
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

  Future<void> deleteField(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.profitFields}/$fieldId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete field response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Field deleted successfully (with cascade)');
        await _notificationService.clearNotificationFlags(fieldId);
      } else {
        throw Exception('Failed to delete field: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Delete field error: $e');
      throw Exception('Failed to delete field: $e');
    }
  }

  Future<Map<String, dynamic>> getFieldExpenses(String fieldId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.profitFields}/$fieldId/expenses'),
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
          'Failed to load field expenses: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Get field expenses error: $e');
      throw Exception('Failed to fetch field expenses: $e');
    }
  }

  // ============================================================
  // REPORT METHODS
  // ============================================================

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

      final uri = Uri.parse(ApiEndpoints.profitReports)
          .replace(queryParameters: queryParams);

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
