import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.alperlab.lol';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userId != null) 'X-User-Id': userId.toString(),
    };
  }

  // ── Local user storage (name, email) ─────────────────────────────────────

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setInt('user_id', user['id'] ?? 0);
  }

  static Future<Map<String, dynamic>> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'id': prefs.getInt('user_id') ?? 0,
    };
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('GET $endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, double>> getMarketRates() async {
    final response = await get('/api/market/rates');
    return response.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  static Future<List<dynamic>> getList(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('GET $endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        String errorMessage = 'Request failed: ${response.statusCode}';
        
        if (body['detail'] != null) {
          if (body['detail'] is List && body['detail'].isNotEmpty) {
             errorMessage = body['detail'][0]['msg'] ?? 'Validation Error';
          } else {
             errorMessage = body['detail'].toString();
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$e');
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('PUT $endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('DELETE $endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await saveUser(response);
    return response;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    await saveUser(response);
    return response;
  }

  static Future<void> logout() async {
    await clearUser();
  }

  // ── Financial ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getFinancialSummary() async {
    return await get('/api/financial/summary');
  }

  static Future<Map<String, dynamic>> updateFinancialSummary(
    Map<String, dynamic> data,
  ) async {
    return await put('/api/financial/summary', data);
  }

  static Future<Map<String, dynamic>> getTransactions({int? year, int? month}) async {
    String queryParams = (year != null && month != null) ? '?year=$year&month=$month' : '';
    return await get('/api/transactions$queryParams');
  }

  static Future<Map<String, dynamic>> addTransaction({
    required String description,
    required double amount,
    required String type,
    String? date,
    int? goalId,
    String category = 'Genel',
    String currency = 'TRY',
    bool isNeed = true,
  }) async {
    return await post('/api/transactions', {
      'description': description,
      'amount': amount,
      'type': type,
      'date': date,
      'goal_id': goalId,
      'category': category,
      'currency': currency,
      'is_need': isNeed,
    });
  }

  // --- SAVINGS METHODS ---
  static Future<List<dynamic>> getSavings() async {
    return await getList('/api/savings');
  }

  static Future<Map<String, dynamic>> addSaving({
    required double amount,
    required String currency,
    required String description,
    required String date,
  }) async {
    return await post('/api/savings', {
      'amount': amount,
      'currency': currency,
      'description': description,
      'date': date,
    });
  }

  static Future<void> deleteSaving(int id) async {
    return await delete('/api/savings/$id');
  }

  static Future<Map<String, dynamic>> getSavingsSummary() async {
    return await get('/api/savings/summary');
  }

  static Future<Map<String, dynamic>> transferSaving({
    required int fromSavingId,
    required String toCurrency,
    String? description,
  }) async {
    return await post('/api/savings/transfer', {
      'from_saving_id': fromSavingId,
      'to_currency': toCurrency,
      if (description != null) 'description': description,
    });
  }

  static Future<Map<String, dynamic>> updateTransaction(
    int id,
    Map<String, dynamic> transaction,
  ) async {
    return await put('/api/transactions/$id', transaction);
  }

  static Future<void> deleteTransaction(int id) async {
    return await delete('/api/transactions/$id');
  }

  // ── Investment profile ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInvestmentProfile() async {
    return await get('/api/investment/profile');
  }

  static Future<Map<String, dynamic>> saveInvestmentProfile(
    String profile,
  ) async {
    return await post('/api/investment/profile', {'profile': profile});
  }

  // ── User profile ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/api/user/profile');
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profile,
  ) async {
    return await put('/api/user/profile', profile);
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getGoals() async {
    return await getList('/api/goals');
  }

  static Future<Map<String, dynamic>> getGoalHistory(int id) async {
    return await get('/api/goals/$id/history');
  }

  static Future<Map<String, dynamic>> createGoal(
    Map<String, dynamic> goalData,
  ) async {
    return await post('/api/goals', goalData);
  }

  static Future<Map<String, dynamic>> updateGoal(
    int id,
    Map<String, dynamic> goalData,
  ) async {
    return await put('/api/goals/$id', goalData);
  }

  static Future<Map<String, dynamic>> purchaseGoal(
    int id,
  ) async {
    return await post('/api/goals/$id/purchase', {});
  }
  
  static Future<void> deleteGoal(int id) async {
    return await delete('/api/goals/$id');
  }

  static Future<Map<String, dynamic>> fundGoalFromSaving(int goalId, int savingId) async {
    return await post('/api/goals/$goalId/fund', {'saving_id': savingId});
  }

  // ── Saved Expenses (Quick-Add Templates) ──────────────────────────────────

  static Future<List<dynamic>> getSavedExpenses() async {
    return await getList('/api/saved-expenses');
  }

  static Future<Map<String, dynamic>> createSavedExpense({
    required String label,
    required double amount,
    String category = 'Genel',
  }) async {
    return await post('/api/saved-expenses', {
      'label': label,
      'amount': amount,
      'category': category,
    });
  }

  static Future<void> deleteSavedExpense(int id) async {
    return await delete('/api/saved-expenses/$id');
  }

  static Future<Map<String, dynamic>> applySavedExpense(int id, {double? overrideAmount}) async {
    final data = <String, dynamic>{};
    if (overrideAmount != null) {
      data['override_amount'] = overrideAmount;
    }
    return await post('/api/saved-expenses/$id/apply', data);
  }
}

