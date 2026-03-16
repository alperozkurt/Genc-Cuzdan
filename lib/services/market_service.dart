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

  static Future<Map<String, double>> getMarketData() async {
    Map<String, double> results = {};
    
    // 1. Fetch Currency Data (USD/TRY, EUR/TRY)
    double usdTry = 34.52; // Internal tracking for gold calculation
    try {
      final response = await http.get(Uri.parse(_exchangeUrl), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          usdTry = (data['rates']['TRY'] as num).toDouble();
          double eurUsd = (data['rates']['EUR'] as num).toDouble();
          
          results['USD/TL'] = usdTry;
          // EUR/TRY = (USD/TRY) / (USD/EUR) -> This is wrong if EUR/USD is given.
          // In the response, EUR is rates['EUR'] which is how many EUR for 1 USD.
          // So EUR/TRY = USD/TRY / rates['EUR']
          results['EUR/TL'] = usdTry / eurUsd;
        }
      }
    } catch (e) {
      print('Currency API error: $e');
    }

    // 2. Fetch Gold Data (XAU/USD)
    try {
      final response = await http.get(Uri.parse(_goldUrl), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['price'] != null) {
          double goldUsdPerOunce = (data['price'] as num).toDouble();
          // Gram Gold TL = (Ounce Price / 31.1034768) * usdTry
          results['Gram Altın'] = (goldUsdPerOunce / 31.1034768) * usdTry;
        }
      }
    } catch (e) {
      print('Gold API error: $e');
    }

    // 3. Fetch BTC Data (BTC/TRY)
    try {
      final response = await http.get(Uri.parse(_btcUrl), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['bitcoin'] != null && data['bitcoin']['try'] != null) {
          results['BTC/TL'] = (data['bitcoin']['try'] as num).toDouble();
        }
      }
    } catch (e) {
      print('BTC API error: $e');
    }

    return results;
  }
}
