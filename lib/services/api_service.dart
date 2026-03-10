import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Replace with your FastAPI server URL
  static const String baseUrl =
      'http://100.68.176.40:8000'; // Remote server — no trailing slash

  // Headers for API requests
  static Future<Map<String, String>> _getHeadersWithToken() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ignore: unused_element
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ignore: unused_element
  static Map<String, String> _getAuthHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeadersWithToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeadersWithToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeadersWithToken();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  static Future<void> delete(String endpoint) async {
    try {
      final headers = await _getHeadersWithToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.containsKey('access_token')) {
        await _saveToken(response['access_token']);
      }

      return response;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.containsKey('access_token')) {
        await _saveToken(response['access_token']);
      }

      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // Financial data endpoints
  static Future<Map<String, dynamic>> getFinancialSummary() async {
    return await get('/api/financial/summary');
  }

  static Future<Map<String, dynamic>> getTransactions() async {
    return await get('/api/transactions');
  }

  static Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transaction,
  ) async {
    return await post('/api/transactions', transaction);
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

  // Investment profile endpoints
  static Future<Map<String, dynamic>> getInvestmentProfile() async {
    return await get('/api/investment/profile');
  }

  static Future<Map<String, dynamic>> saveInvestmentProfile(
    String profile,
  ) async {
    return await post('/api/investment/profile', {'profile': profile});
  }

  // User endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/api/user/profile');
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profile,
  ) async {
    return await put('/api/user/profile', profile);
  }
}
