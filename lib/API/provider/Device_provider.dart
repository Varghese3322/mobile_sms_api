import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_details.dart';

class DeviceProvider extends ChangeNotifier {
  DeviceDetails? _deviceDetails;

  bool _isLoading = false;
  bool _isRegistered = false;
  String? _message;

  static const String _keyRegistered = "device_registered";
  static const String _keyDeviceData = "device_data";

  DeviceDetails? get deviceDetails => _deviceDetails;
  bool get isLoading => _isLoading;
  bool get isRegistered => _isRegistered;
  String? get message => _message;

  /// 🔹 Load saved device status on app start
  Future<void> loadDeviceStatus() async {
    final prefs = await SharedPreferences.getInstance();

    _isRegistered = prefs.getBool(_keyRegistered) ?? false;

    final deviceJson = prefs.getString(_keyDeviceData);

    if (deviceJson != null && deviceJson.isNotEmpty) {
      final decoded = jsonDecode(deviceJson);

      if (decoded != null && decoded is Map<String, dynamic>) {
        _deviceDetails = DeviceDetails.fromJson(decoded);
      } else {
        // corrupted or "null" saved earlier
        _deviceDetails = null;
        await prefs.remove(_keyDeviceData);
      }
    }

    notifyListeners();
  }

  /// 🔹 Register Device API
  Future<void> registerDevice(Map<String, dynamic> payload) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final url = Uri.parse("http://sms.apihub.co.in/api/device/register/");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      final responseData = jsonDecode(response.body);
      final bool hasPlan = responseData["has_plan"] == true;

      final prefs = await SharedPreferences.getInstance();

      if (response.statusCode == 200 && hasPlan) {
        _isRegistered = true;
        _message = responseData["message"] ?? "Device Registered Successfully!";

        final device = responseData["device"];

        if (device != null && device is Map<String, dynamic>) {
          _deviceDetails = DeviceDetails.fromJson(device);
          await prefs.setString(_keyDeviceData, jsonEncode(device));
        } else {
          _deviceDetails = null;
          await prefs.remove(_keyDeviceData);
        }

        await prefs.setBool(_keyRegistered, true);
      } else {
        _isRegistered = false;
        _message =
            responseData["message"] ?? "No active plan. Please buy a plan.";

        await prefs.setBool(_keyRegistered, false);
        await prefs.remove(_keyDeviceData);
      }
    } catch (e) {
      print("Exception: $e");
      _isRegistered = false;
      _message = "Something went wrong. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 🔹 Unregister device (local logout)
  Future<void> clearDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isRegistered = false;
    _deviceDetails = null;
    notifyListeners();
  }
}
