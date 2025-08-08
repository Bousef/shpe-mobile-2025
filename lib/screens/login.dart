import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shpeucfmobile/screens/admindashboard.dart';
import 'package:shpeucfmobile/screens/dashboard.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';

final supabaseService = SupabaseService();

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage; // 👈 Add error message state

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),

          SafeArea(
            minimum: const EdgeInsets.only(top: 55),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Column(
                      children: [
                        const SHPEHeaderText(text: 'WELCOME BACK'),
                        const SizedBox(height: 210),

                        InputField(
                          text: 'UCF Email',
                          controller: emailController,
                        ),
                        const SizedBox(height: 15),
                        PasswordInputField(
                          text: 'Password',
                          controller: passwordController,
                        ),
                        const SizedBox(height: 5),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/');
                                print('clicked forgot password!');
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFFF1F3F7),
                                  fontSize: 15,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Login ',
                          backgroundColor: const Color(0xFFF2AC02),
                          textColor: const Color(0xFFF1F3F7),
                          onPressed: () async {
                            setState(() {
                              errorMessage = null; // Clear any previous error
                            });

                            try {
                              final fbUser = await FirebaseAuthService().login(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );

                              if (fbUser == null) {
                                setState(() {
                                  errorMessage =
                                      "Invalid email or password. Please try again.";
                                });
                                return;
                              }

                              final userRole = await supabaseService
                                  .fetchUserRole(fbUser.uid);

                              if (userRole == null) {
                                setState(() {
                                  errorMessage =
                                      "User not found in our database.";
                                });
                                return;
                              }

                              final isAdmin =
                                  userRole['is_admin'] as bool? ?? false;

                              if (isAdmin) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const Admindashboard(),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Dashboard(),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Login error: $e');
                              setState(() {
                                errorMessage =
                                    "Invalid email or password. Please try again.";
                              });
                            }
                          },
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFF1F3F7),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                                print('clicked sign up!');
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFF1F3F7),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SHPEHeaderText extends StatelessWidget {
  final String text;

  const SHPEHeaderText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Adumu',
            fontSize: 45,
            color: Color(0xFFF2AC02),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Adumu',
            fontSize: 45,
            foreground:
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = Colors.black,
          ),
        ),
      ],
    );
  }
}
