import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class MarketService {
  static const String _exchangeUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _goldUrl = 'https://api.gold-api.com/price/XAU';
  static const String _btcUrl = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=try';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  };

  static const Map<String, double> _fallbacks = {
    'USD/TL': 44.36,
    'EUR/TL': 51.45,
    'Gram Altın': 6500.0,
    'BTC/TL': 3160000.0,
  };

  static Future<http.Response?> _fetchWithRetry(String url) async {
    for (int i = 0; i < 3; i++) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return response;
        }
        print('Request to $url returned status: ${response.statusCode} (Attempt ${i + 1})');
      } catch (e) {
        print('Attempt ${i + 1} failed for $url: $e');
      }
      if (i < 2) {
        // Wait before retrying: 2s, 4s
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    return null;
  }

  static Future<Map<String, double>> getMarketData() async {
    try {
      // Fetch consolidated rates from our backend (much faster)
      final rates = await ApiService.getMarketRates();
      
      // Ensure all expected keys are present, fallback if missing
      Map<String, double> results = Map.from(_fallbacks);
      rates.forEach((key, value) {
        results[key] = value;
      });
      
      print('Market data fetched from backend successfully');
      return results;
    } catch (e) {
      print('Failed to fetch market data from backend, using fallbacks: $e');
      return _fallbacks;
    }
  }
}
