import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<void> updateSmsStatusBg({
  required int smsId,
  required String status,
}) async {
  final url = Uri.parse("http://sms.apihub.co.in/api/update-status/");

  final body = {
    "sms_id": smsId,
    "status": status,
  };

  try {
    log("🚀 BG UPDATE STATUS API CALLED");
    log("📤 BODY: $body");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    log("📥 BG STATUS CODE: ${response.statusCode}");
    log("📥 BG RESPONSE: ${response.body}");
  } catch (e) {
    log("❌ BG STATUS UPDATE ERROR: $e");
  }
}
