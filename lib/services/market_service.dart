import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MarketService {
  static const Map<String, double> _fallbacks = {
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

  static Map<String, double>? _cachedLiveRates;
  static DateTime? _lastFetchTime;
  static bool _isFetching = false;

  /// Returns cached/fallback market rates instantly (0ms) to avoid UI frame blocking,
  /// and updates rates asynchronously in the background.
  static Future<Map<String, double>> fetchLiveRates() async {
    if (_cachedLiveRates == null) {
      _cachedLiveRates = Map<String, double>.from(_fallbacks);
      _lastFetchTime = DateTime.now();
      _fetchBackgroundRates();
    } else if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes >= 5) {
      _fetchBackgroundRates();
    }
    return Map<String, double>.from(_cachedLiveRates!);
  }

  static void _fetchBackgroundRates() async {
    if (_isFetching) return;
    _isFetching = true;
    final Map<String, double> liveRates = Map<String, double>.from(_cachedLiveRates ?? _fallbacks);

    try {
      final erResponse = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 4));

      if (erResponse.statusCode == 200) {
        final data = json.decode(erResponse.body);
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.containsKey('TRY')) {
          final usdTry = (rates['TRY'] as num).toDouble();
          liveRates['USD/TL'] = usdTry;

          if (rates.containsKey('EUR') && (rates['EUR'] as num) > 0) {
            liveRates['EUR/TL'] = usdTry / (rates['EUR'] as num).toDouble();
          }
          if (rates.containsKey('GBP') && (rates['GBP'] as num) > 0) {
            liveRates['GBP/TL'] = usdTry / (rates['GBP'] as num).toDouble();
          }
          if (rates.containsKey('JPY') && (rates['JPY'] as num) > 0) {
            liveRates['JPY/TL'] = usdTry / (rates['JPY'] as num).toDouble();
          }
          if (rates.containsKey('CHF') && (rates['CHF'] as num) > 0) {
            liveRates['CHF/TL'] = usdTry / (rates['CHF'] as num).toDouble();
          }
          if (rates.containsKey('CNY') && (rates['CNY'] as num) > 0) {
            liveRates['CNY/TL'] = usdTry / (rates['CNY'] as num).toDouble();
          }
          liveRates['Gram Altın'] = (usdTry * 2400) / 31.1035;
          liveRates['Gümüş'] = (usdTry * 28.5) / 31.1035;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fiat rate fetch note: $e');
    }

    try {
      final cryptoResponse = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=try'))
          .timeout(const Duration(seconds: 4));

      if (cryptoResponse.statusCode == 200) {
        final cryptoData = json.decode(cryptoResponse.body);
        if (cryptoData['bitcoin'] != null && cryptoData['bitcoin']['try'] != null) {
          liveRates['BTC/TL'] = (cryptoData['bitcoin']['try'] as num).toDouble();
        }
        if (cryptoData['ethereum'] != null && cryptoData['ethereum']['try'] != null) {
          liveRates['ETH/TL'] = (cryptoData['ethereum']['try'] as num).toDouble();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Crypto rate fetch note: $e');
    }

    _cachedLiveRates = liveRates;
    _lastFetchTime = DateTime.now();
    _isFetching = false;
  }

  static Future<Map<String, double>> getMarketData() async {
    return fetchLiveRates();
  }
}
