// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class LeaderboardScreen extends StatefulWidget {
//   @override
//   _MyWidgetState createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<LeaderboardScreen> {
//   @override
//   void initState() {
//     super.initState(); // ✅ Correct usage
//     testSupabase(); // Call your Supabase test here
//   }

//   Future<void> testSupabase() async {
//     final supabase = Supabase.instance.client;

//     try {
//       final List data = await supabase.from('users').select('firstname');
//       for (var user in data) {
//         print(user['firstname']);
//       }
//     } catch (error) {
//       print('Error fetching first names: $error');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(body: Center(child: Text('Check console')));
//   }
// }
