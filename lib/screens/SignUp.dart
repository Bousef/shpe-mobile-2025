import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ucfidController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  bool _isLoading = false;
  DateTime? _lastTap;

  bool _debouncedTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(seconds: 1)) {
      return false; // ignore rapid double taps within 1s
    }
    _lastTap = now;
    return true;
  }

  String? _validateInputs() {
    final email = emailController.text.trim();
    final pass  = passwordController.text.trim();
    final first = firstNameController.text.trim();
    final last  = lastNameController.text.trim();
    final ucfid = ucfidController.text.trim();
    final bday  = birthdayController.text.trim();

    if ([first, last, email, pass, ucfid, bday].any((v) => v.isEmpty)) {
      return "Please fill out all fields.";
    }

    final ucfEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@ucf\.edu$');
    if (!ucfEmail.hasMatch(email)) {
      return "Please use a valid UCF email (…@ucf.edu).";
    }

    if (int.tryParse(ucfid) == null) {
      return "UCF ID must be numeric.";
    }

    final dateOk = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(bday);
    if (!dateOk) {
      return "Birthday must be in YYYY-MM-DD format.";
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    // hard reentrancy guard
    if (_isLoading) {
      debugPrint('SIGNUP: blocked (already loading)');
      return;
    }
    setState(() => _isLoading = true);
    debugPrint('SIGNUP: start');

    FocusScope.of(context).unfocus(); // close keyboard

    final authService = FirebaseAuthService();
    final supabaseService = SupabaseService();

    // 1) Validate input
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      setState(() => _isLoading = false);
      debugPrint('SIGNUP: validation failed');
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final first = firstNameController.text.trim();
    final last  = lastNameController.text.trim();
    final ucfid = int.parse(ucfidController.text.trim());
    final birthday = birthdayController.text.trim();

    // 2) Optional pre-check to avoid duplicate work if the code ever gets called twice
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        // Already exists; guide user
        debugPrint('SIGNUP: precheck found existing: $methods');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An account for $email already exists. Please log in or reset your password.")),
        );
        setState(() => _isLoading = false);
        return;
      }
    } catch (_) {
      // If precheck fails (rare), proceed; the create call will still error correctly if email exists
    }

    // 3) Create Firebase User
    User? createdUser;
    try {
      createdUser = await authService.signUp(email, password);
      if (createdUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected: no user returned from Firebase.")),
        );
        setState(() => _isLoading = false);
        debugPrint('SIGNUP: no user returned');
        return;
      }
      debugPrint('SIGNUP: created ${createdUser.uid}');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase sign-up failed: ${e.message}")),
      );
      setState(() => _isLoading = false);
      debugPrint('SIGNUP: firebase error ${e.code} ${e.message}');
      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error during sign-up: $e")),
      );
      setState(() => _isLoading = false);
      debugPrint('SIGNUP: unexpected $e');
      return;
    }

    // 4) Send verification email (non-fatal)
    try {
      await createdUser.sendEmailVerification();
      debugPrint('SIGNUP: sent verification');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not send verification email yet: $e")),
      );
      debugPrint('SIGNUP: verification email error $e');
    }

    // 5) Insert profile into Supabase; if this fails, optionally roll back Firebase
    try {
      await supabaseService.insertUser(
        firebaseUid: createdUser.uid,
        email: createdUser.email ?? email,
        firstname: first,
        lastname: last,
        ucfid: ucfid,
        birthday: birthday,
      );
      debugPrint('SIGNUP: supabase insert ok');
    } catch (e) {
      debugPrint('SIGNUP: supabase insert failed $e — attempting rollback');
      try {
        await createdUser.delete(); // works immediately post-signup
        debugPrint('SIGNUP: rollback delete ok');
      } catch (delErr) {
        debugPrint('SIGNUP: rollback delete failed $delErr');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created, but saving your profile failed. Please try again.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 6) Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verification email sent. Please verify, then log in.")),
    );
    setState(() => _isLoading = false);
    debugPrint('SIGNUP: done → navigate login');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('lib/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(top: 50),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 180),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SHPEHeaderText(text: 'CREATE ACCOUNT'),
                        const SizedBox(height: 43),
                        InputField(text: 'First Name', controller: firstNameController),
                        const SizedBox(height: 25),
                        InputField(text: 'Last Name', controller: lastNameController),
                        const SizedBox(height: 25),
                        InputField(text: 'UCF Email', controller: emailController),
                        const SizedBox(height: 25),
                        InputField(text: 'UCF ID', controller: ucfidController),
                        const SizedBox(height: 25),
                        PasswordInputField(text: 'Password', controller: passwordController),
                        const SizedBox(height: 25),
                        TextField(
                          controller: birthdayController,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final formatted =
                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              birthdayController.text = formatted;
                            }
                          },
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F3F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(30.0)),
                            ),
                            labelText: "Birthday (YYYY-MM-DD)",
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      CustomButton(
                        text: _isLoading ? 'Please wait…' : 'Sign Up',
                        backgroundColor: const Color(0xFFF2AC02),
                        textColor: const Color(0xFFF1F3F7),
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_debouncedTap()) {
                                  _handleSignUp();
                                } else {
                                  debugPrint('SIGNUP: debounced tap ignored');
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          text: 'Already Registered? ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFF1F3F7),
                          ),
                          children: [
                            TextSpan(
                              text: 'Log in here.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFF1F3F7),
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/login');
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
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
            fontSize: 41,
            color: Color(0xFFF2AC02),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Adumu',
            fontSize: 41,
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
