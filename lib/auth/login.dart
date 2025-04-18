import 'dart:convert';
import 'package:bracu_core/auth/signup.dart';
import 'package:bracu_core/home/bottom_navigationbar.dart';
import 'package:bracu_core/home/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_root.dart';
import '../service/profile_provider.dart';
import '../widgets/custom_input_field.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final _formKey = GlobalKey<FormState>();
  bool passEnable = true;
  bool isPasswordcorrect = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> handle_login() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      const String uri = "${api_root}/api/auth/login";

      final Map<String, dynamic> requestBody = {
        "gsuite": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      try {
        final response = await http.post(
          Uri.parse(uri),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        );

        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        if (kDebugMode) {
          print(response.body);
        }
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          // Save jsonResponse in ProfileProvider
          final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.saveProfileData(jsonResponse);
          await profileProvider.saveAuthToken(jsonResponse['token']);
          await profileProvider.updateLoginStatus(true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavBar(),
            ),
          );

        } else if (response.statusCode == 400) {
          final jsonResponse = json.decode(response.body);
          Fluttertoast.showToast(msg: "⚠️ Login failed. ${jsonResponse['message']}");
          if (kDebugMode) {
            print("Login failed: ${response.statusCode}");
          }
        }
      } catch (error) {
        if (context.mounted) Navigator.of(context).pop();
        Fluttertoast.showToast(msg: "🚨 Network error. Please check your connection.");
        if (kDebugMode) {
          print("Error: $error");
        }
      }
    }
  }


  Future<void> LogInStatus(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  void _togglePasswordVisibility() {
    setState(() {
      passEnable = !passEnable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/Login.png'),
            fit: BoxFit.cover,
          ),
        ),

        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  SizedBox(height: 160),

                  Center(
                    child: Image.asset(
                        "assets/logo/bracu_core.png",
                        width: 200),
                  ),

                  const Text(
                    "Login!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      fontFamily: "nicomoji",
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      children: [


                        CustomInputField(
                          controller: _emailController,
                          hintText: "gsuite email",
                          icon: Icons.email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your GSuite email";
                            } else if (!RegExp(r'^[^@]+@g\.bracu\.ac\.bd$').hasMatch(value)) {
                              return "Please enter a valid GSuite email";
                            }
                            return null;
                          },
                        ),
                        CustomInputField(
                          controller: _passwordController,
                          hintText: "Password",
                          icon: Icons.lock,
                          isPassword: true,
                          isPasswordVisible: !passEnable,
                          onTogglePasswordVisibility: _togglePasswordVisibility,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            } else if (value.length < 8) {
                              return "Password must be at least 8 characters long";
                            }
                            return null;
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 0),
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Fluttertoast.showToast(
                                  msg: 'Not Applicable right now',
                                  gravity: ToastGravity.TOP);
                            },
                            child: const Text(
                              'Forgot password',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 20, right: 20, left: 20),
                            child: SizedBox(
                              height: 60,
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.all(18),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    handle_login();
                                  }
                                },
                                child: const Text(
                                  "Log In",
                                  style: TextStyle(fontSize: 18, letterSpacing: .4, color: Color(0xFFD45858)),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildButton(),


                      ],
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

  Widget _buildButton() {
    return TextButton(
        onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Registration()));
        },
        child: Text(
          "Register ?",
            style: TextStyle(
                color: Colors.white,
              letterSpacing:  1.5,
              fontSize: 18,
            ),
        )
    );
  }
}