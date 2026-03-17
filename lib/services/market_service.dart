import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  static const String _exchangeUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _goldUrl = 'https://api.gold-api.com/price/XAU';
  static const String _btcUrl = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=try';

  static const Map<String, String> _headers = {
    'User-Agent': 'GencCuzdan/1.0',
    'Accept': 'application/json',
  };

  static const Map<String, double> _fallbacks = {
    'USD/TL': 34.52,
    'EUR/TL': 37.89,
    'Gram Altın': 2445.75,
    'BTC/TL': 1352450.0,
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
    // Start with fallback values to ensure we always return something
    Map<String, double> results = Map.from(_fallbacks);
    
    // 1. Fetch Currency Data (USD/TRY, EUR/TRY)
    double usdTry = _fallbacks['USD/TL']!;
    try {
      final response = await _fetchWithRetry(_exchangeUrl);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          usdTry = (data['rates']['TRY'] as num).toDouble();
          double eurUsd = (data['rates']['EUR'] as num).toDouble();
          
          results['USD/TL'] = usdTry;
          // EUR/TRY = USD/TRY / (USD to EUR rate)
          results['EUR/TL'] = usdTry / eurUsd;
        }
      }
    } catch (e) {
      print('Currency processing error: $e');
    }

    // 2. Fetch Gold Data (XAU/USD)
    try {
      final response = await _fetchWithRetry(_goldUrl);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['price'] != null) {
          double goldUsdPerOunce = (data['price'] as num).toDouble();
          // Gram Gold TL = (Ounce Price / 31.1034768) * usdTry
          results['Gram Altın'] = (goldUsdPerOunce / 31.1034768) * usdTry;
        }
      }
    } catch (e) {
      print('Gold processing error: $e');
    }

    // 3. Fetch BTC Data (BTC/TRY)
    try {
      final response = await _fetchWithRetry(_btcUrl);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['bitcoin'] != null && data['bitcoin']['try'] != null) {
          results['BTC/TL'] = (data['bitcoin']['try'] as num).toDouble();
        }
      }
    } catch (e) {
      print('BTC processing error: $e');
    }

    return results;
  }
}
