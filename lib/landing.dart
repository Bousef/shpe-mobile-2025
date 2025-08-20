import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/profile.dart';
import 'package:shpeucfmobile/widgets/events_carousel.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shpeucfmobile/widgets/shpe_header_text.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  List<Map<String, dynamic>> topUsers = [];
  bool isLoading = true;
  late final SupabaseService _service;
  late final Future<List<Event>> _eventsFuture;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserFirstName;

  @override
  void initState() {
    super.initState();
    _service = SupabaseService();
    _eventsFuture = _service.fetchEvents();
    fetchTopUsers();
    fetchCurrentUser();
  }

  Future<void> fetchTopUsers() async {
    final supabase = Supabase.instance.client;
    try {
      final List data = await supabase
          .from('users')
          .select('firstname, points')
          .order('points', ascending: false)
          .limit(5);

      setState(() {
        topUsers = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching users: $error');
      setState(() => isLoading = false);
    }
  }

Future<void> fetchCurrentUser() async {
  final firebaseUser = _auth.currentUser;
  final firebaseUid = firebaseUser?.uid;

  print('Firebase UID: $firebaseUid'); // debug

  if (firebaseUid == null) {
    print('No user is signed in.');
    return;
  }

  try {
    final userData = await _service.getUserByFirebaseUid(firebaseUid);
    print('Supabase User Data: $userData'); // debug

    setState(() {
      currentUserFirstName = userData?['firstname'];
    });
  } catch (e) {
    print("Error fetching current user from Supabase: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          Positioned.fill(
            top: screenHeight * 0.01,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(width: 50), // eventually put notifications button here
                            SvgPicture.asset('lib/images/SHPE_Logo.svg', width: 150),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder:(context) => Profile())
                                );
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF2AC02),
                                  shape: BoxShape.circle
                                ),
                                child: Image.asset(
                                  'lib/images/Profile2.png', width: 50, color: Colors.black
                                )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (currentUserFirstName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SHPEHeaderText(
                              text: 'Welcome $currentUserFirstName!',
                              fontSize: 32,
                            ),
                          ),



                        const SizedBox(height: 20),
                        Image.asset(
                          'lib/images/events.png',
                          width: screenWidth * 0.43,
                          height: 45,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: FutureBuilder<List<Event>>(
                            future: _eventsFuture,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.white));
                              }
                              if (snap.hasError) {
                                return Center(child: Text('Error: ${snap.error}'));
                              }
                              final allEvents = snap.data ?? [];
                              final now = DateTime.now();

                              final upcomingEvents = allEvents.where((event) {
                                if(event.date == null) return false; //skips if no date
                                //filter events so only present and future shows up
                                return event.date!.isAtSameMomentAs(DateTime(now.year, now.month, now.day)) || event.date!.isAfter(DateTime(now.year, now.month, now.day));
                              }).toList();
                              if (upcomingEvents.isEmpty) {
                                return const Center(child: Text('No upcoming events.'));
                              }
                              return EventsCarousel(events: upcomingEvents);
                            },
                          ),
                        ),
                        const SizedBox(height: 25),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              'lib/images/leaderboardWord2.png',
                              width: screenWidth * 0.75,
                              height: 45,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            if (!isLoading && topUsers.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(topUsers.length, (index) {
                                  final user = topUsers[index];
                                  final img = _service.getAvatarUrl(user['firstname']);
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: SizedBox(
                                            width: screenWidth * 0.15,
                                            height: screenWidth * 0.17,
                                            child: SvgPicture.network(img, fit: BoxFit.cover),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['firstname'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user['points'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
