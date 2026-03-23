import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmSmsTestPage extends StatefulWidget {
  const FcmSmsTestPage({super.key});

  @override
  State<FcmSmsTestPage> createState() => _FcmSmsTestPageState();
}

class _FcmSmsTestPageState extends State<FcmSmsTestPage> {
  static const platform = MethodChannel("native_sms");

  final List<String> logs = [];
  final phoneController = TextEditingController();
  final msgController = TextEditingController();

  void addLog(String text) {
    setState(() => logs.insert(0, text));
    debugPrint(text);
  }

  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  // ---------------- FCM SETUP ----------------
  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    String? token = await messaging.getToken();
    addLog("📱 FCM TOKEN:\n$token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      addLog("🔥 FCM RECEIVED");
      addLog("📦 DATA: ${message.data}");

      final data = message.data;

      if (data['type']?.toString().toUpperCase() != 'SEND_SMS') return;

      final phone = data['phone'] ?? '';
      final text = data['message'] ?? '';

      if (phone.isEmpty || text.isEmpty) {
        addLog("❌ Missing SMS data");
        return;
      }

      sendSms(phone, text);
    });
  }

  // ---------------- SEND SMS ----------------
  Future<void> sendSms(String phone, String message) async {
    try {
      addLog("📤 Sending SMS...");

      final res = await platform.invokeMethod("sendSms", {
        "phone": phone,
        "message": message,
      });

      addLog("✅ RESULT: $res");
    } catch (e) {
      addLog("❌ ERROR: $e");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FCM SMS TEST")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              sendSms(
                phoneController.text,
                msgController.text,
              );
            },
            child: const Text("SEND TEST SMS"),
          ),
          const Divider(),
          const Text("LOGS"),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: logs.length,
              itemBuilder: (_, i) => Text(logs[i]),
            ),
          )
        ],
      ),
    );
  }
}
