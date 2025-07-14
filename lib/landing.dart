import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shpeucfmobile/profile.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/widgets/events_carousel.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _service = SupabaseService();
    _eventsFuture = supabaseService.fetchEvents();
    fetchTopUsers();
  }

  Future<void> fetchTopUsers() async {
    final supabase = Supabase.instance.client;
    // fetching leaderboard data
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

  

  

// TODO: fix issues with scaling (maybe try spaceAround?)
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
                    padding: EdgeInsets.only(bottom: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SvgPicture.asset('lib/images/SHPE_Logo.svg', width: 150),
                        SizedBox(height: screenHeight * 0.011),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Profile()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF2AC02),
                              foregroundColor: Color.fromARGB(255, 31, 62, 105),
                              textStyle: const TextStyle(fontFamily: 'Poppins'),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Text(
                                    'PROFILE',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ClipOval(
                                    child: Image.asset(
                                      'lib/images/Profile2.png',
                                      width: 70,
                                      height: 75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    
                        // -----------EVENTS AREA
                        SizedBox(height: screenHeight * 0.017),
                        Image.asset(
                          'lib/images/events.png',
                          width: screenWidth * 0.43,
                          height: 45,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: screenHeight * 0.017),
                        Container(
                          height: 200,
                          child: FutureBuilder<List<Event>>(
                            future: _eventsFuture,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snap.hasError) {
                                return Center(child: Text('Error: ${snap.error}'));
                              }
                              final events = snap.data ?? [];
                              if (events.isEmpty) {
                                return const Center(child: Text('no events yet'));
                              }
                              return EventsCarousel(events: events);
                            },
                          ),
                        ),
                        // -----LEADERBOARD
                        SizedBox(height: screenHeight * 0.019),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              'lib/images/leaderboardWord2.png',
                              width: screenWidth * 0.75,
                              height: 45,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 10),
                            if (!isLoading && topUsers.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(topUsers.length, (index) {
                                  final user = topUsers[index];
                                  final img = _service.getAvatarUrl(user['firstname']);
                                  
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.015,
                                    ),
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: SizedBox(
                                            width: screenWidth * 0.15,
                                            height: screenWidth * 0.17,
                                          child: SvgPicture.network(
                                            img,
                                            fit: BoxFit.cover,
                                            
                                          ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['firstname'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold, 
                                            )
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

// -----------------Leaderboards HERE -----------
          // Positioned(
          //   bottom: screenHeight * 0.12,
          //   left: 0,
          //   right: 0,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //       Image.asset(
          //         'lib/images/leaderboardWord2.png',
          //         width: screenWidth * 0.75,
          //         height: 45,
          //         fit: BoxFit.contain,
          //       ),
          //       SizedBox(height: 10),
          //       if (!isLoading && topUsers.isNotEmpty)
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: List.generate(topUsers.length, (index) {
          //             final user = topUsers[index];
          //             final img = _service.getAvatarUrl(user['firstname']);
                      
          //             return Padding(
          //               padding: EdgeInsets.symmetric(
          //                 horizontal: screenWidth * 0.015,
          //               ),
          //               child: Column(
          //                 children: [
          //                   ClipOval(
          //                     child: SizedBox(
          //                       width: screenWidth * 0.15,
          //                       height: screenWidth * 0.17,
          //                     child: SvgPicture.network(
          //                       img,
          //                       fit: BoxFit.cover,
                                
          //                     ),
          //                     ),
          //                   ),
          //                   const SizedBox(height: 4),
          //                   Text(
          //                     user['firstname'],
          //                     style: const TextStyle(
          //                       color: Colors.white,
          //                       fontWeight: FontWeight.bold, 
          //                       )
          //                   ),
          //                   Text(
          //                     user['points'].toString(),
          //                     style: const TextStyle(
          //                       color: Colors.white,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             );
          //           }),
          //         ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
