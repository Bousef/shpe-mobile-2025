import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/Instagram.dart';
import 'package:shpeucfmobile/screens/dashboard.dart';
import 'package:shpeucfmobile/screens/homescreen.dart';
import 'package:shpeucfmobile/screens/leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/screens/SignUp.dart';
import 'package:shpeucfmobile/services/photo_service.dart';

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

  final service = PhotoService(Supabase.instance.client);
  // Example usage of the PhotoService to fetch photos with reactions
  // 1. Fetch the list
  const testEventId = 'a8fb5b63-7193-4a6b-a4cb-0163b064ff78';
  try {
    final photos = await service.fetchEventPhotosWithReactions(testEventId);

    // 2. Print each entry
    debugPrint('Fetched ${photos.length} photos:');
    for (final p in photos) {
      debugPrint('Photo ${p.photoId} by ${p.uploaderName} @ ${p.createdAt}');
      for (final r in p.reactions) {
        debugPrint('  • ${r.type}: ${r.count}');
      }
    }
  } catch (e) {
    debugPrint('Error fetching photos: $e');
  }

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
