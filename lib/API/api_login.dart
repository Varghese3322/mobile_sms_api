import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String loginUrl = "http://sms.apihub.co.in/api/login/";

  static Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    final url = Uri.parse(loginUrl);

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode({
        "email_or_username": emailOrUsername,
        "password": password,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }
}
