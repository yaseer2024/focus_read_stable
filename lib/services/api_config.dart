import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? baseUrl;

  // 🔒 Remote config URL (ngrok / future VPS)
  static const String configUrl =
      'https://morphologic-attendantly-nada.ngrok-free.dev/config';

  static Future<void> load() async {
    try {
      final res = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        baseUrl = data['apiBaseUrl'];
        print("✅ Connected to server: $baseUrl");
        return;
      }
    } catch (e) {
      print("⚠️ Server not reachable, running offline");
    }

    // 🔥 OFFLINE MODE
    baseUrl = null;
  }
}