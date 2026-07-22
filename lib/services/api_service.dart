import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'market_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.alperlab.lol';
  static bool _isDemoMode = false;

  static void enableDemoMode() {
    _isDemoMode = true;
  }

  static bool get isDemoMode => _isDemoMode;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userId != null) 'X-User-Id': userId.toString(),
    };
  }

  // ── Local user storage ──────────────────────────────────────────────────

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

  /// Initialize demo user data without API calls
  static Future<void> setDemoUser({
    required String email,
    required String password,
    required String name,
  }) async {
    enableDemoMode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setInt('user_id', 1);
  }

  // ── Demo / Mock In-Memory Repository ───────────────────────────────────

  static int _nextDemoId = 100;

  static final Map<String, double> _demoFinancialSummary = {
    'monthly_income': 24500.0,
    'monthly_expense': 9850.0,
    'monthly_savings': 14650.0,
  };

  static final List<Map<String, dynamic>> _demoTransactions = [
    {
      'id': 1,
      'description': 'Aylık Maaş Ödemesi',
      'amount': 21000.0,
      'type': 'gelir',
      'category': 'Maaş',
      'date': '2025-02-01',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 2,
      'description': 'Serbest Proje Geliri (Mobil Uygulama)',
      'amount': 3500.0,
      'type': 'gelir',
      'category': 'Serbest',
      'date': '2025-02-10',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 3,
      'description': 'Haftalık Süpermarket Alışverişi',
      'amount': 1850.0,
      'type': 'gider',
      'category': 'Gıda',
      'date': '2025-02-05',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 4,
      'description': 'Aylık Toplu Taşıma & Akbil',
      'amount': 650.0,
      'type': 'gider',
      'category': 'Ulaşım',
      'date': '2025-02-03',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 5,
      'description': 'İnternet & Telefon Faturası',
      'amount': 480.0,
      'type': 'gider',
      'category': 'Fatura',
      'date': '2025-02-07',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 6,
      'description': 'Sinema & Konser Bileti',
      'amount': 350.0,
      'type': 'gider',
      'category': 'Eğlence',
      'date': '2025-02-15',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': false,
    },
    {
      'id': 7,
      'description': 'İngilizce Kitap Seti',
      'amount': 420.0,
      'type': 'gider',
      'category': 'Eğitim',
      'date': '2025-02-09',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 8,
      'description': 'Yazılım Eğitimi Birikim Katkısı',
      'amount': 800.0,
      'type': 'gelir',
      'category': 'Eğitim',
      'date': '2025-02-12',
      'goal_id': 4,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 9,
      'description': 'Restoran & Yemek',
      'amount': 320.0,
      'type': 'gider',
      'category': 'Gıda',
      'date': '2025-02-18',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': false,
    },
    {
      'id': 10,
      'description': 'Spor Salonu Aylık Ücreti',
      'amount': 650.0,
      'type': 'gider',
      'category': 'Spor',
      'date': '2025-02-20',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 11,
      'description': 'Netflix & Spotify Aboneliği',
      'amount': 290.0,
      'type': 'gider',
      'category': 'Abonelik',
      'date': '2025-02-22',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': false,
    },
    {
      'id': 12,
      'description': 'MacBook Birikim Depozitosu',
      'amount': 450.0,
      'type': 'gelir',
      'category': 'Alışveriş',
      'date': '2025-02-25',
      'goal_id': 1,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 13,
      'description': 'Ek Gelir — Özel Ders',
      'amount': 1500.0,
      'type': 'gelir',
      'category': 'Serbest',
      'date': '2025-02-27',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 14,
      'description': 'Kahve & Atıştırmalık',
      'amount': 120.0,
      'type': 'gider',
      'category': 'Gıda',
      'date': '2025-02-14',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': false,
    },
    {
      'id': 15,
      'description': 'Taksi & Ulaşım',
      'amount': 240.0,
      'type': 'gider',
      'category': 'Ulaşım',
      'date': '2025-02-16',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 16,
      'description': 'Kitap Alışverişi',
      'amount': 180.0,
      'type': 'gider',
      'category': 'Eğitim',
      'date': '2025-02-24',
      'goal_id': null,
      'currency': 'TRY',
      'is_need': true,
    },
    {
      'id': 17,
      'description': 'Haftalık Birikim Transferi',
      'amount': 500.0,
      'type': 'gelir',
      'category': 'Birikim',
      'date': '2025-02-28',
      'goal_id': 3,
      'currency': 'TRY',
      'is_need': true,
    },
  ];

  static final List<Map<String, dynamic>> _demoGoals = [
    {
      'id': 1,
      'name': 'Yeni Laptop (MacBook Pro M3)',
      'target_amount': 45000.0,
      'current_amount': 32000.0,
      'icon_key': 'computer_rounded',
      'color_key': 'indigo',
      'deadline': '2025-12-31',
      'is_completed': false,
      'monthly_target': 3500.0,
      'is_need': true,
    },
    {
      'id': 2,
      'name': 'Avrupa Tatili (Interrail)',
      'target_amount': 25000.0,
      'current_amount': 14500.0,
      'icon_key': 'flight_takeoff_rounded',
      'color_key': 'orange',
      'deadline': '2025-08-15',
      'is_completed': false,
      'monthly_target': 2500.0,
      'is_need': false,
    },
    {
      'id': 3,
      'name': 'Acil Durum Birikim Fonu',
      'target_amount': 20000.0,
      'current_amount': 14600.0,
      'icon_key': 'shield_rounded',
      'color_key': 'teal',
      'deadline': '2025-11-30',
      'is_completed': false,
      'monthly_target': 2000.0,
      'is_need': true,
    },
    {
      'id': 4,
      'name': 'Yazılım Eğitimi & Sertifika',
      'target_amount': 6000.0,
      'current_amount': 4200.0,
      'icon_key': 'school_rounded',
      'color_key': 'purple',
      'deadline': '2025-06-30',
      'is_completed': false,
      'monthly_target': 1000.0,
      'is_need': true,
    },
    {
      'id': 5,
      'name': 'Kablosuz Kulaklık (AirPods Max)',
      'target_amount': 12000.0,
      'current_amount': 12000.0,
      'icon_key': 'headphones_rounded',
      'color_key': 'amber',
      'deadline': '2025-01-10',
      'is_completed': true,
      'monthly_target': 2000.0,
      'is_need': false,
    },
    {
      'id': 6,
      'name': 'Spor Salonu Yıllık Üyelik',
      'target_amount': 6000.0,
      'current_amount': 6000.0,
      'icon_key': 'fitness_center_rounded',
      'color_key': 'green',
      'deadline': '2025-01-20',
      'is_completed': true,
      'monthly_target': 1500.0,
      'is_need': true,
    },
  ];

  static final List<Map<String, dynamic>> _demoSavings = [
    {
      'id': 1,
      'amount': 15000.0,
      'currency': 'TRY',
      'description': 'Vadeli Mevduat Hesabı (%45 Faiz)',
      'date': '2025-01-15',
    },
    {
      'id': 2,
      'amount': 650.0,
      'currency': 'USD',
      'description': 'Döviz Birikim Hesabı',
      'date': '2025-02-01',
    },
    {
      'id': 3,
      'amount': 400.0,
      'currency': 'EUR',
      'description': 'Avrupa Gezi Birikim Hesabı',
      'date': '2025-02-10',
    },
    {
      'id': 4,
      'amount': 8.5,
      'currency': 'GOLD',
      'description': 'Fiziki Çeyrek & Gram Altın Birikimi',
      'date': '2025-02-18',
    },
  ];

  static final List<Map<String, dynamic>> _demoSavedExpenses = [
    {'id': 1, 'label': 'Kahve & Tatlı', 'amount': 85.0, 'category': 'Gıda'},
    {
      'id': 2,
      'label': 'Otobüs & Metro Kartı',
      'amount': 140.0,
      'category': 'Ulaşım',
    },
    {
      'id': 3,
      'label': 'Süpermarket Alışverişi',
      'amount': 350.0,
      'category': 'Gıda',
    },
    {'id': 4, 'label': 'Yemek Siparişi', 'amount': 220.0, 'category': 'Gıda'},
    {
      'id': 5,
      'label': 'Sinema & Bilet',
      'amount': 180.0,
      'category': 'Eğlence',
    },
    {
      'id': 6,
      'label': 'Kitap & Kırtasiye',
      'amount': 160.0,
      'category': 'Eğitim',
    },
  ];

  static final Map<String, dynamic> _demoUserProfile = {
    'name': 'Alper Özkurt',
    'email': 'demo@genccuzdan.app',
    'job_type': 'çalışan',
    'monthly_salary': 24500.0,
  };

  static final Map<String, dynamic> _demoInvestmentProfile = {
    'profile': 'Dengeli',
  };

  // ── Financial Data Getters ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getFinancialSummary() async {
    if (_isDemoMode) {
      double income = 0;
      double expense = 0;
      for (var t in _demoTransactions) {
        final amt = (t['amount'] as num).toDouble();
        if (t['type'] == 'gelir') {
          income += amt;
        } else {
          expense += amt;
        }
      }
      return {
        'monthly_income': income,
        'monthly_expense': expense,
        'monthly_savings': (income - expense).clamp(0.0, double.infinity),
      };
    }
    return await get('/api/financial/summary');
  }

  static Future<Map<String, dynamic>> getTransactions({
    int? year,
    int? month,
  }) async {
    if (_isDemoMode) {
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      final filledTransactions = _demoTransactions.map((t) {
        final origDate = DateTime.tryParse(t['date'].toString()) ?? now;
        final day = origDate.day.clamp(1, 28);
        final monthStr = targetMonth.toString().padLeft(2, '0');
        final dayStr = day.toString().padLeft(2, '0');
        final newDateStr = '$targetYear-$monthStr-$dayStr';
        return {...t, 'date': newDateStr};
      }).toList();

      final income = filledTransactions.where((t) => t['type'] == 'gelir').toList();
      final expenses = filledTransactions.where((t) => t['type'] == 'gider').toList();
      return {
        'income': income,
        'expenses': expenses,
        'activities': List<Map<String, dynamic>>.from(filledTransactions),
      };
    }
    String queryParams = (year != null && month != null)
        ? '?year=$year&month=$month'
        : '';
    return await get('/api/transactions$queryParams');
  }

  static Future<List<dynamic>> getGoals() async {
    if (_isDemoMode) {
      return List<dynamic>.from(_demoGoals);
    }
    return await getList('/api/goals');
  }

  static Future<List<dynamic>> getSavings() async {
    if (_isDemoMode) {
      return List<dynamic>.from(_demoSavings);
    }
    return await getList('/api/savings');
  }

  static Future<Map<String, dynamic>> getSavingsSummary() async {
    if (_isDemoMode) {
      double tryTot = 0;
      double usdTot = 0;
      double eurTot = 0;
      double btcTot = 0;
      double ethTot = 0;
      double goldTot = 0;

      for (var item in _demoSavings) {
        final amt = (item['amount'] as num).toDouble();
        final rawCurr = (item['currency'] ?? 'TRY').toString().toUpperCase();
        // Normalize 'GRAM ALTIN' → 'GOLD' for backward compat
        final curr = (rawCurr == 'GRAM ALTIN' || rawCurr == 'ALTIN')
            ? 'GOLD'
            : rawCurr;
        if (curr == 'TRY') {
          tryTot += amt;
        } else if (curr == 'USD') {
          usdTot += amt;
        } else if (curr == 'EUR') {
          eurTot += amt;
        } else if (curr == 'BTC') {
          btcTot += amt;
        } else if (curr == 'ETH') {
          ethTot += amt;
        } else if (curr == 'GOLD') {
          goldTot += amt;
        }
      }

      return {
        'total_try': tryTot,
        'total_usd': usdTot,
        'total_eur': eurTot,
        'total_btc': btcTot,
        'total_eth': ethTot,
        'total_gold_grams': goldTot,
      };
    }
    return await get('/api/savings/summary');
  }

  static Future<List<dynamic>> getSavedExpenses() async {
    if (_isDemoMode) {
      return List<dynamic>.from(_demoSavedExpenses);
    }
    return await getList('/api/saved-expenses');
  }

  static Future<Map<String, dynamic>> getInvestmentProfile() async {
    if (_isDemoMode) {
      return Map<String, dynamic>.from(_demoInvestmentProfile);
    }
    return await get('/api/investment/profile');
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    if (_isDemoMode) {
      return Map<String, dynamic>.from(_demoUserProfile);
    }
    return await get('/api/user/profile');
  }

  static Future<Map<String, double>> getMarketRates() async {
    if (_isDemoMode) {
      try {
        return await MarketService.fetchLiveRates();
      } catch (_) {
        return {
          'USD/TL': 32.45,
          'EUR/TL': 35.20,
          'GBP/TL': 41.10,
          'JPY/TL': 0.215,
          'CHF/TL': 36.80,
          'CNY/TL': 4.50,
          'Gram Altın': 2850.0,
          'Gümüş': 32.50,
          'BTC/TL': 1850000.0,
          'ETH/TL': 62000.0,
        };
      }
    }
    final response = await get('/api/market/rates');
    return response.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
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
    if (_isDemoMode) {
      _demoUserProfile['name'] = name;
      _demoUserProfile['email'] = email;
      await saveUser(_demoUserProfile);
      return Map<String, dynamic>.from(_demoUserProfile);
    }
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
    if (_isDemoMode) {
      await saveUser(_demoUserProfile);
      return Map<String, dynamic>.from(_demoUserProfile);
    }
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

  // ── Transactions Mutations ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateFinancialSummary(
    Map<String, dynamic> data,
  ) async {
    if (_isDemoMode) {
      if (data.containsKey('monthly_income')) {
        _demoFinancialSummary['monthly_income'] =
            (data['monthly_income'] as num).toDouble();
      }
      if (data.containsKey('monthly_expense')) {
        _demoFinancialSummary['monthly_expense'] =
            (data['monthly_expense'] as num).toDouble();
      }
      _demoFinancialSummary['monthly_savings'] =
          (_demoFinancialSummary['monthly_income'] ?? 0) -
          (_demoFinancialSummary['monthly_expense'] ?? 0);
      return Map<String, dynamic>.from(_demoFinancialSummary);
    }
    return await put('/api/financial/summary', data);
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
    if (_isDemoMode) {
      final newId = ++_nextDemoId;
      final txDate = date ?? DateTime.now().toString().split(' ')[0];
      final item = {
        'id': newId,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'date': txDate,
        'goal_id': goalId,
        'currency': currency,
        'is_need': isNeed,
      };
      _demoTransactions.insert(0, item);

      // Recalculate summary
      if (type == 'gelir') {
        _demoFinancialSummary['monthly_income'] =
            (_demoFinancialSummary['monthly_income'] ?? 0) + amount;
      } else {
        _demoFinancialSummary['monthly_expense'] =
            (_demoFinancialSummary['monthly_expense'] ?? 0) + amount;
      }
      _demoFinancialSummary['monthly_savings'] =
          (_demoFinancialSummary['monthly_income'] ?? 0) -
          (_demoFinancialSummary['monthly_expense'] ?? 0);

      return item;
    }

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

  static Future<Map<String, dynamic>> updateTransaction(
    int id,
    Map<String, dynamic> transaction,
  ) async {
    if (_isDemoMode) {
      final index = _demoTransactions.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _demoTransactions[index] = {
          ..._demoTransactions[index],
          ...transaction,
        };
        return Map<String, dynamic>.from(_demoTransactions[index]);
      }
      return transaction;
    }
    return await put('/api/transactions/$id', transaction);
  }

  static Future<void> deleteTransaction(int id) async {
    if (_isDemoMode) {
      _demoTransactions.removeWhere((t) => t['id'] == id);
      return;
    }
    return await delete('/api/transactions/$id');
  }

  // ── Savings Mutations ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addSaving({
    required double amount,
    required String currency,
    required String description,
    required String date,
  }) async {
    if (_isDemoMode) {
      final item = {
        'id': ++_nextDemoId,
        'amount': amount,
        'currency': currency,
        'description': description,
        'date': date,
      };
      _demoSavings.add(item);
      return item;
    }
    return await post('/api/savings', {
      'amount': amount,
      'currency': currency,
      'description': description,
      'date': date,
    });
  }

  static Future<void> deleteSaving(int id) async {
    if (_isDemoMode) {
      _demoSavings.removeWhere((s) => s['id'] == id);
      return;
    }
    return await delete('/api/savings/$id');
  }

  static Future<Map<String, dynamic>> transferSaving({
    required int fromSavingId,
    required String toCurrency,
    String? description,
  }) async {
    if (_isDemoMode) {
      final index = _demoSavings.indexWhere((s) => s['id'] == fromSavingId);
      if (index != -1) {
        _demoSavings[index]['currency'] = toCurrency;
        if (description != null) {
          _demoSavings[index]['description'] = description;
        }
        return Map<String, dynamic>.from(_demoSavings[index]);
      }
      return {};
    }
    return await post('/api/savings/transfer', {
      'from_saving_id': fromSavingId,
      'to_currency': toCurrency,
      'description': ?description,
    });
  }

  // ── Investment Profile ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveInvestmentProfile(
    String profile,
  ) async {
    if (_isDemoMode) {
      _demoInvestmentProfile['profile'] = profile;
      return Map<String, dynamic>.from(_demoInvestmentProfile);
    }
    return await post('/api/investment/profile', {'profile': profile});
  }

  // ── User Profile ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profile,
  ) async {
    if (_isDemoMode) {
      _demoUserProfile.addAll(profile);
      await saveUser(_demoUserProfile);
      return Map<String, dynamic>.from(_demoUserProfile);
    }
    return await put('/api/user/profile', profile);
  }

  // ── Goals Mutations ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getGoalHistory(int id) async {
    if (_isDemoMode) {
      final goal = _demoGoals.firstWhere(
        (g) => g['id'] == id,
        orElse: () => _demoGoals.first,
      );
      final current =
          ((goal['current_amount'] ?? goal['target_amount'] ?? 5000) as num)
              .toDouble();
      return {
        '2024-10': current * 0.2,
        '2024-11': current * 0.45,
        '2024-12': current * 0.7,
        '2025-01': current * 0.85,
        '2025-02': current,
      };
    }
    return await get('/api/goals/$id/history');
  }

  static Future<Map<String, dynamic>> createGoal(
    Map<String, dynamic> goalData,
  ) async {
    if (_isDemoMode) {
      final newGoal = {
        'id': ++_nextDemoId,
        'name': goalData['name'] ?? 'Yeni Hedef',
        'target_amount':
            (goalData['target_amount'] as num?)?.toDouble() ?? 1000.0,
        'current_amount':
            (goalData['current_amount'] as num?)?.toDouble() ?? 0.0,
        'icon_key': goalData['icon_key'] ?? 'stars_rounded',
        'color_key': goalData['color_key'] ?? 'blue',
        'deadline': goalData['deadline'] ?? '2025-12-31',
        'is_completed': false,
        'monthly_target':
            (goalData['monthly_target'] as num?)?.toDouble() ?? 500.0,
      };
      _demoGoals.add(newGoal);
      return newGoal;
    }
    return await post('/api/goals', goalData);
  }

  static Future<Map<String, dynamic>> updateGoal(
    int id,
    Map<String, dynamic> goalData,
  ) async {
    if (_isDemoMode) {
      final index = _demoGoals.indexWhere((g) => g['id'] == id);
      if (index != -1) {
        _demoGoals[index] = {..._demoGoals[index], ...goalData};
        return Map<String, dynamic>.from(_demoGoals[index]);
      }
      return goalData;
    }
    return await put('/api/goals/$id', goalData);
  }

  static Future<Map<String, dynamic>> purchaseGoal(int id) async {
    if (_isDemoMode) {
      final index = _demoGoals.indexWhere((g) => g['id'] == id);
      if (index != -1) {
        _demoGoals[index]['is_completed'] = true;
        _demoGoals[index]['current_amount'] =
            _demoGoals[index]['target_amount'];
        return Map<String, dynamic>.from(_demoGoals[index]);
      }
      return {};
    }
    return await post('/api/goals/$id/purchase', {});
  }

  static Future<void> deleteGoal(int id) async {
    if (_isDemoMode) {
      _demoGoals.removeWhere((g) => g['id'] == id);
      return;
    }
    return await delete('/api/goals/$id');
  }

  static Future<Map<String, dynamic>> fundGoalFromSaving(
    int goalId,
    int savingId,
  ) async {
    if (_isDemoMode) {
      final gIndex = _demoGoals.indexWhere((g) => g['id'] == goalId);
      final sIndex = _demoSavings.indexWhere((s) => s['id'] == savingId);
      if (gIndex != -1 && sIndex != -1) {
        final savingAmount = (_demoSavings[sIndex]['amount'] as num).toDouble();
        final currentAmt = (_demoGoals[gIndex]['current_amount'] as num)
            .toDouble();
        final targetAmt = (_demoGoals[gIndex]['target_amount'] as num)
            .toDouble();

        final updatedGoalAmt = (currentAmt + savingAmount).clamp(
          0.0,
          targetAmt,
        );
        _demoGoals[gIndex]['current_amount'] = updatedGoalAmt;
        if (updatedGoalAmt >= targetAmt) {
          _demoGoals[gIndex]['is_completed'] = true;
        }

        return Map<String, dynamic>.from(_demoGoals[gIndex]);
      }
      return {};
    }
    return await post('/api/goals/$goalId/fund', {'saving_id': savingId});
  }

  // ── Saved Expenses (Quick-Add Templates) ──────────────────────────────────

  static Future<Map<String, dynamic>> createSavedExpense({
    required String label,
    required double amount,
    String category = 'Genel',
  }) async {
    if (_isDemoMode) {
      final item = {
        'id': ++_nextDemoId,
        'label': label,
        'amount': amount,
        'category': category,
      };
      _demoSavedExpenses.add(item);
      return item;
    }
    return await post('/api/saved-expenses', {
      'label': label,
      'amount': amount,
      'category': category,
    });
  }

  static Future<void> deleteSavedExpense(int id) async {
    if (_isDemoMode) {
      _demoSavedExpenses.removeWhere((se) => se['id'] == id);
      return;
    }
    return await delete('/api/saved-expenses/$id');
  }

  static Future<Map<String, dynamic>> applySavedExpense(
    int id, {
    double? overrideAmount,
  }) async {
    if (_isDemoMode) {
      final item = _demoSavedExpenses.firstWhere(
        (se) => se['id'] == id,
        orElse: () => {},
      );
      if (item.isNotEmpty) {
        final amountToApply =
            overrideAmount ?? (item['amount'] as num).toDouble();
        return await addTransaction(
          description: item['label'] ?? 'Hızlı Harcama',
          amount: amountToApply,
          type: 'gider',
          category: item['category'] ?? 'Genel',
        );
      }
      return {};
    }
    final data = <String, dynamic>{};
    if (overrideAmount != null) {
      data['override_amount'] = overrideAmount;
    }
    return await post('/api/saved-expenses/$id/apply', data);
  }
}
