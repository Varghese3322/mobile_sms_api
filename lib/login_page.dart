import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'API/api_login.dart';
import 'Home_screen.dart';

class Login_page_Sms extends StatefulWidget {
  const Login_page_Sms({super.key});

  @override
  State<Login_page_Sms> createState() => _Login_page_SmsState();
}

class _Login_page_SmsState extends State<Login_page_Sms> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;



  Future<void> _launchSignupUrl() async {
    final Uri url = Uri.parse("http://sms.apihub.co.in");

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open signup page")),
      );
    }
  }





  void _loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email and Password cannot be empty")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.login(email, password);

      if (response["success"] == true) {

        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLoggedIn", true);

        // ✅ SAVE USER ID (MOST IMPORTANT)
        await prefs.setInt("user_id", response["user_id"]);

        // optional
        await prefs.setString("email", response["email"]);


        if (_ischecked) {
          await prefs.setBool("remember_me", true);
          await prefs.setString("saved_email", email);
          await prefs.setString("saved_password", password);
        } else {
          await prefs.remove("remember_me");
          await prefs.remove("saved_email");
          await prefs.remove("saved_password");
        }


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home_screen()),
        );
      }

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Login failed")),
        );
      }
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      isLoading = false;
    });
  }


  bool _ischecked = true;
  bool passwordVisible = true;




  Future<bool> _makeCall() async {
    var status = await Permission.phone.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone permission is required.")),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }

    return false;
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();

    bool rememberMe = prefs.getBool("remember_me") ?? false;

    if (rememberMe) {
      emailController.text = prefs.getString("saved_email") ?? "";
      passwordController.text = prefs.getString("saved_password") ?? "";
    }

    setState(() {
      _ischecked = rememberMe;
    });

    // Auto-login if already logged in
    if (prefs.getBool("isLoggedIn") == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Home_screen()),
      );
    }
  }



  void initState() {
    super.initState();

    passwordVisible = true;

    _loadRememberedUser();


    Future.delayed(Duration(milliseconds: 300), () {
      _makeCall();
    });
  }



  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// LOGO & TITLE ---------------------------
                  Row(
                    children: [
                      Image.network(
                        "https://cdn-icons-png.flaticon.com/512/3109/3109329.png",
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Mobile Sms Api",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      )
                    ],
                  ),

                  SizedBox(height: height * 0.05),

                  const Text(
                    "Sign-In",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  const Text(
                    "Access the MobileSmsApi using your email and password",
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: height * 0.03),

                  /// EMAIL ---------------------------
                  const Text(
                    "Email or Username",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: "Enter your email address or username",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.03),

                  /// PASSWORD ---------------------------
                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: passwordVisible,
                    decoration: InputDecoration(
                      hintText: "Enter your password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      suffixIcon: IconButton(
                          onPressed: (){
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                          icon: Icon(
                              passwordVisible ?
                              Icons.visibility
                                  : Icons.visibility_off),


                      )
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// SIGN-IN BUTTON ---------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child:
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: isLoading ? null : () async {
                        bool granted = await _makeCall();
                        if (!granted) return;

                        _loginUser();
                      },

                      child: isLoading
                       ?  CircularProgressIndicator(color: Colors.white,)
                       : const Text(
                        "Sign in",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// REMEMBER + SIGN UP -------------------------
                  Row(
                    children: [
                      Checkbox(
                        value: _ischecked,
                        onChanged: (value) {
                          setState(() => _ischecked = value!);
                        },
                      ),
                      const Text("Remember me"),
                      const Spacer(),
                      GestureDetector(
                        onTap: _launchSignupUrl,
                        child: const Text(
                          "First time here? Sign up",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    ],
                  ),

                  const Spacer(),

                  /// FOOTER -------------------------------------
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: Text(
                        "©2025 MobileSmsApi. All rights Reserved.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionManager {
  static Future<bool> requestPhonePermissions() async {
    // Request multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      // You can add other permissions here if needed, like Permission.manageOwnCalls
    ].request();

    PermissionStatus phoneStatus = statuses[Permission.phone]!;

    if (phoneStatus.isGranted) {
      // The user granted the permission
      return true;
    } else if (phoneStatus.isDenied) {
      // The user denied the permission, but it can be requested again
      // You might show a rationale here before requesting again
      return false;
    } else if (phoneStatus.isPermanentlyDenied) {
      // The user permanently denied the permission (e.g., checked "Don't ask again")
      // You should guide them to the app settings
      openAppSettings(); // Opens the app's settings screen
      return false;
    }

    return false;
  }
}
class PermissionDialog extends StatelessWidget {
  final Permission permissionType;

  const PermissionDialog({Key? key, required this.permissionType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Permission Required"),
      content: Text("This app needs ${permissionType.toString().split('.').last} permission for core functionality."),
      actions: <Widget>[
        TextButton(
          child: Text("Deny"),
          onPressed: () {
            // Dismiss dialog and return false
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: Text("Allow"),
          onPressed: () {
            // Dismiss dialog and return true to proceed with native request
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}