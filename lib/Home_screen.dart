
import 'dart:developer';

import 'package:another_telephony/telephony.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'API/provider/Device_provider.dart';
import 'API/provider/recive_sms_provider.dart';
import 'API/provider/saveFCM.dart';
import 'API/provider/sms_status.dart';





int? userId;




class Home_screen extends StatefulWidget {
  const Home_screen({super.key});

  @override
  State<Home_screen> createState() => _Home_screenState();
}

class _Home_screenState extends State<Home_screen> {


  int dailySms = 100;


  Future<Map?> sendNativeSms({
    required String phone,
    required String message,
    int sim = 0,
    bool rotation = true,
  }) async {
    try {
      final result = await platform.invokeMethod<Map>("sendSms", {
        "phone": phone,
        "message": message,
        "sim": sim,
      });

      log("✅ SMS SENT | SIM: $sim | NEXT SIM: $result");

      return result;
    } catch (e) {
      log("❌ SMS ERROR: $e");
      return null;
    }
  }



  Future<void> unregisterDeviceAndLogout() async {
    try {
      await context.read<DeviceProvider>().registerDevice({
        "android_id": androidId,
        "user_id": userId,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 🔥 Close loading dialog
      Navigator.pop(context);

      // 🔥 Navigate to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );

    } catch (e) {
      Navigator.pop(context); // close loading if error
      debugPrint("Unregister Error: $e");
    }
  }






  static const platform = MethodChannel("native_sms");


  int _currentSim = 0;


  //  Sim rotation
  int getNextSim() {
    int sim = _currentSim;
    _currentSim = (_currentSim + 1) % 2;
    return sim;
  }


  final Telephony telephony = Telephony.instance;





  final msgService = FirebaseMessaging.instance;



  Future<void> requestSmsPermission() async {
    await Permission.phone.request();
    await Permission.sms.request();


  }




  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("user_id", userId);
  }



  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt("user_id");

    debugPrint("LOADED USER ID: $storedId");

    setState(() {
      userId = storedId;
    });
  }








  TextEditingController sim1Controller = TextEditingController();
  TextEditingController sim2Controller = TextEditingController();




  static const MethodChannel simChannel = MethodChannel('sim_info');

  List simList = [];

  Future<void> loadSimInfo() async {
    try {
      final result = await simChannel.invokeMethod('getSimInfo');
      print("SIM RESULT: $result");


      setState(() {
        simList = result;
      });

    } catch (e) {
      print("SIM Error: $e");
    }
  }








  bool isSwitched = false;
  bool isSwitched2 = false;
  bool isSwitched3 = false;


  String deviceModel = "";
  String androidId = "";



  @override
  void initState()async {
    super.initState();

    loadSimInfo();

    initStartup(); // ✅ async method called separately
    await Permission.phone.request();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;

      if (data['type'] == 'SEND_SMS') {
        final phone = data['phone'] ?? '';
        final msg = data['message'] ?? '';
        final sim = int.tryParse(data['sim'] ?? '0') ?? 0;
        final smsId = int.tryParse(data['sms_id'] ?? '0') ?? 0;

        if (phone.isEmpty || msg.isEmpty || smsId == 0) {
          log("❌ Invalid FCM data");
          return;
        }

        try {
          final result = await platform.invokeMethod<Map>("sendSms", {
            "phone": phone,
            "message": msg,
            "sim": sim,
          });

          final bool success = result?["success"] == true;

          await context.read<SmsStatusProvider>().updateSmsStatus(
            smsId: smsId,
            status: success ? "sent" : "failed",
          );

        } catch (e) {
          await context.read<SmsStatusProvider>().updateSmsStatus(
            smsId: smsId,
            status: "failed",
          );
        }
      }
    });

    if (userId != null) {
      testReceiveSmsApi();
    }

    Future.microtask(() {
      context.read<DeviceProvider>().loadDeviceStatus();
    });
  }


  Future<void> testReceiveSmsApi() async {
    debugPrint("🚀 testReceiveSmsApi CALLED");

    if (userId == null) {
      debugPrint("❌ userId is null");
      return;
    }

    debugPrint("📤 Preparing SMS API payload");

    final provider = context.read<ReceiveSmsProvider>();

    debugPrint("➡ Calling sendIncomingSms()");

    await provider.sendIncomingSms(
      userId: userId!,
      deviceId: 2,
      sim: 0,
      fromNumber: "7306944930",
      message: "SMS Api testing",
    );

    debugPrint("⬅ sendIncomingSms() finished");

    if (provider.success) {
      debugPrint("✅ RECEIVE SMS API SUCCESS");
    } else {
      debugPrint("❌ API ERROR: ${provider.error}");
    }
  }




  // -------------------- FCM SETUP --------------------
  Future<void> initFCM() async {
    print("bhvb");
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $token");

    if (token != null && userId != null && androidId.isNotEmpty) {
      await saveFcmToken(userId: userId!, androidId: androidId, fcmToken: token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("FCM TOKEN REFRESHED: $newToken");
      if (userId != null && androidId.isNotEmpty) {
        saveFcmToken(userId: userId!, androidId: androidId, fcmToken: newToken);
      }
    });
            print("djsd");




  }







  Future<void> initStartup() async {
    await loadUserId();      // 👈 ensure userId exists
    await getDeviceInfo();   // 👈 ensure androidId exists

    await initFCM();         // 👈 now safe to save token

    Future.microtask(() async {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        final result = await Permission.sms.request();
        if (!result.isGranted) {
          debugPrint("SMS permission denied");
          return;
        }
      }
    });
  }



  Future<void> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;

    setState(() {
      deviceModel = "${android.manufacturer} ${android.model}";
      androidId = android.id;
    });
  }














  void showUnregisterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          title: const Text(
            "Confirm",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to Unregister this device?",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("NO"),
            ),
            TextButton(
              onPressed: () async {

                Navigator.pop(context); // close dialog

                await unregisterDeviceAndLogout();

              },
              child: const Text("YES"),
            ),
          ],
        );
      },
    );
  }








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.network(
              "https://cdn-icons-png.flaticon.com/512/3109/3109329.png",
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              "MobileSmsApi",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Consumer<DeviceProvider>(
              builder: (context, provider, _) {
                final bool registered = provider.isRegistered;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "●",
                      style: TextStyle(
                        color: registered ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      registered ? "REGISTERED" : "UNREGISTERED",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],


      ),

      // BODY
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---------------- DEVICE CARD ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade500,
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          deviceModel.isEmpty ? "Loading..." : deviceModel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Consumer<DeviceProvider>(
                          builder: (context, provider, _) {

                            // hide once registered
                            if (provider.isRegistered || deviceModel.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              onPressed: provider.isLoading || userId == null
                                  ? null
                                  : () async {
                                final sim0Number = sim1Controller.text;
                                final sim1Number = sim2Controller.text;

                                final payload = {
                                  "android_id": androidId,
                                  "device_name": deviceModel,
                                  "brand": deviceModel.split(" ").first,
                                  "model": deviceModel,
                                  "user_id": userId,

                                  // SIM 0
                                  "network_name0": simList.isNotEmpty ? simList[0]['carrierName'] : "",
                                  "sim_mobile0": sim0Number,
                                  "daily_limit0": 100,
                                  "remaining_sms0": 100,


                                  // SIM 1
                                  "network_name1": simList.length > 1 ? simList[1]['carrierName'] : "",
                                  "sim_mobile1": sim1Number,
                                  "daily_limit1": 50,
                                  "remaining_sms1": 50,
                                };

                                await context
                                    .read<DeviceProvider>()
                                    .registerDevice(payload);

                                final msg = context.read<DeviceProvider>().message;
                                if (msg != null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(msg)));
                                }
                              },
                              child: const Text("REGISTER DEVICE"),
                            );
                          },
                        ),


                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      androidId.isEmpty ? "Fetching ID..." : androidId,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Consumer<DeviceProvider>(
                      builder: (context, provider, _) {
                        return Text(
                          provider.isRegistered
                              ? "Your device is successfully registered."
                              : "Your device is not registered. Please register your device.",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- AUTO START BOX ----------------
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.horizontal(),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Text(
                      "Please use below button to Auto Start App permission to run App in Background.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {

                          AppSettings.openAppSettings();



                        },
                        child: const Text("Allow Auto Start",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ---------------- SMS STATISTICS ----------------
              const Text(
                "Sms Statistics",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const Text(
                "Here is list of today usage sms.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // sim slot  0
              if (simList.isNotEmpty)
                   Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              simList.isNotEmpty
                                  ? "SIM Slot: ${simList[0]['slotIndex']} • ${simList[0]['carrierName']}"
                                  : "SIM Slot: 0",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 5,),
                            Text(
                              sim1Controller.text.isEmpty ? "${simList[0]['number']}" : sim1Controller.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                          ],
                        ),



                        const Spacer(),

                        Text(
                          "Send SMS",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),

                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isSwitched,
                              onChanged: (value) async {
                                setState(() {
                                  isSwitched = value;
                                });

                                if (value) {
                                  // async work here if needed
                                }
                              },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.blue,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade400,
                            trackOutlineColor:
                            WidgetStateProperty.all(Colors.grey.shade400),
                          ),
                        ),
                      ],

                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Daily Sms", style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 4),
                              Text(
                                "99",
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(left: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Unused Sms", style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 4),
                              Text(
                                "0",
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),


              SizedBox(height: 10,),

              // sim slot  1
              if (simList.length > 1)
                   Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(2),
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              simList.length > 1
                                  ? "SIM Slot: ${simList[1]['slotIndex']} • ${simList[1]['carrierName']}"
                                  : "SIM Slot: 1",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 5,),
                            Text(
                              sim2Controller.text.isEmpty ? "No Number" : sim2Controller.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          ],
                        ),

                        const Spacer(),

                        Text(
                          "Send SMS",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),

                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isSwitched3,
                            onChanged: (value) {
                              setState(() async {
                                isSwitched3 = value;

                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.blue,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade400,
                            trackOutlineColor:
                            WidgetStateProperty.all(Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$dailySms",
                                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text("99", style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(left: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Unused Sms",
                                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text("0", style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 25),

              // ---------------- COUNTRY CODE ----------------
              const Text(
                "Country Code",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const Text(
                "Set your country code with + sign.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    SizedBox(
                      width: 150,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {},
                        child:
                        const Text("Update Country Code",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),




              // ---------------- DEVICE SETTINGS ----------------
              const Text(
                "Device Settings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
              const Text(
                "Unregister your device or SignOut setting.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 45,
                child:
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    side: BorderSide(color: Colors.blue),
                  ),
                  onPressed: () {
                    showUnregisterDialog();
                  },
                  child: const Text(
                    "UNREGISTER DEVICE",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

              ),

              const SizedBox(height: 25),
              const Center(
                child: Text(
                  "MobileSmsApi App V2.0",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

