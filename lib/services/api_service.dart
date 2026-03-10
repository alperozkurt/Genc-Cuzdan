import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your FastAPI server URL
  static const String baseUrl =
      'http://100.68.176.40:8000/'; // Change this to your actual API URL

  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
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
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
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
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
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
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
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
