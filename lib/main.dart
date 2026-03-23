import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Providers
import 'API/provider/Device_provider.dart';
import 'API/provider/recive_sms_provider.dart';
import 'API/provider/sms_status.dart';

// Screens
import 'Home_screen.dart';
import 'login_page.dart';
import 'splash_screen.dart';

import 'package:flutter/services.dart';


/// 🔥 Background handler (MUST be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data["type"] == "SEND_SMS") {
    const platform = MethodChannel('native_sms');

    await platform.invokeMethod("sendSms", {
      "phone": message.data["phone"],
      "message": message.data["message"],
      "sim": int.parse(message.data["sim"]),
    });
  }
}

/// ================= MAIN =================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Background handler
  FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);

  // ✅ Foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.data["type"] == "SEND_SMS") {
      const platform = MethodChannel('native_sms');

      await platform.invokeMethod("sendSms", {
        "phone": message.data["phone"],
        "message": message.data["message"],
        "sim": int.parse(message.data["sim"]),
      });
    }
  });

  runApp(const MyApp());
}

/// ================= APP ROOT =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DeviceProvider()..loadDeviceStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReceiveSmsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SmsStatusProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mobile SMS API',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routes: {
          '/login': (_) => const Login_page_Sms(),
          '/home': (_) => const Home_screen(),
        },
        home: const Splash_Screen(),
      ),
    );
  }
}
