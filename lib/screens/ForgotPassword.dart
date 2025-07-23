import 'package:flutter/material.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPassword();
}

class _ForgotPassword extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  String? errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    //need to verify the email entered is in the database
    final email = emailController.text.trim();
    print(email);

    if (!(email.endsWith('@ucf.edu') || email.endsWith('@shpeucf.com'))) {
      print(email.endsWith('@ucf.edu'));
      setState(() {
        errorMessage = "Invalid Email";
        print(errorMessage);
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        errorMessage = null;
      });

      //INSERT FIREBASE SENDPASSWORDRESETEMAIL() METHOD

      setState(() {
        errorMessage = "Password reset email sent!";
        print(errorMessage);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(' ', style: TextStyle(fontSize: 0, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFF2AC02),
        toolbarHeight: 60,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),

          SafeArea(
            minimum: const EdgeInsets.only(top: 55),
            child: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(child: const SHPEHeaderText(text: 'FORGOT PASSWORD')),
                ),
                const SizedBox(height: 210),
                Positioned(
                  top: 250,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        InputField(text: 'UCF Email', controller: emailController),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkEmail,
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text('Send Reset Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2AC02),
                              foregroundColor: const Color(0xFFF1F3F7),
                              textStyle: TextStyle(
                                //fontFamily: 'Poppins',
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (errorMessage != null)
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color:
                                  errorMessage!.startsWith("Password")
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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
