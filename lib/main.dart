import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/dashboard.dart';
import 'package:shpeucfmobile/screens/homescreen.dart';
import 'package:shpeucfmobile/screens/leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/screens/SignUp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}


// Define a stateless widget called MyApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Hides the debug banner in the top-right corner
     home: const HomeScreen(),
      routes: {
        '/login': (context) => Login(),
        '/signup': (context) => SignUp(),
      }
    );
  }
}
