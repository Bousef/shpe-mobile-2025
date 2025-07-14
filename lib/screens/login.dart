import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/admindashboard.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';
import 'package:shpeucfmobile/screens/homescreen.dart';
import 'package:shpeucfmobile/screens/dashboard.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';

final supabaseService = SupabaseService();

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
          // Background image
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
                        // Header
                        const SHPEHeaderText(text: 'WELCOME BACK'),
                        const SizedBox(height: 210),

                        // Email and password input fields
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

                        // Forgot password link
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
                        )
                      ],
                    ),
                  ),
                ),

                // Login button and sign-up redirect
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
                            try {
                              //Logic to login in with firebase auth
                              final fbUser = await FirebaseAuthService().login(emailController.text.trim(), passwordController.text.trim());

                              if(fbUser == null){ 
                                //TODO add a notification saying email or password is wrong
                                }

                              final userRole = await supabaseService.fetchUserRole(fbUser!.uid);
                              final isAdmin = userRole?['is_admin'] as bool? ?? false;
                              final position = userRole?['position'] as String?;

                              if(isAdmin){
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                                   );
                              } else{
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Dashboard()),
                                   );
                              }
                    
                            } catch (e) {
                              print('Navigation error: $e');
                              
                              // for testing just let user pass but in the future remove this 
                              Navigator.pushReplacement(   
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Dashboard()),
                                  );
                            }
                          },
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
                        )
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

// Header font widget
class SHPEHeaderText extends StatelessWidget {
  final String text;

  const SHPEHeaderText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fill
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Adumu',
            fontSize: 45,
            color: Color(0xFFF2AC02),
          ),
        ),
        // Outline
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Adumu',
            fontSize: 45,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
      ],
    );
  }
}
