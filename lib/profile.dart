import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<Map<String, dynamic>> curUser = [];
  bool isLoading = true;
  bool isLoading2 = true;
  int _selectedIndex = 0;
  int leaderboardPosition = 0;
  final SupabaseService _service = SupabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchUserFromService();
    getLeaderboardPosition();
  }

  Future<void> fetchUserFromService() async {
    try {
      final firebaseUser = _auth.currentUser;
      final firebaseUid = firebaseUser?.uid;

      if (firebaseUid == null) {
        print('No Firebase user logged in');
        setState(() => isLoading = false);
        return;
      }

      final Map<String, dynamic> userInfo =
        await Supabase.instance.client
          .from('users')
          .select('firstname, lastname, points, created_at, events_attended, major')
          .eq('id', userId)
          .single();

      setState(() {
        curUser = [userInfo];
        isLoading = false;
        print('curUser = $curUser');
        });

    } catch (error) {
      print('Error fetching user: $error');
      setState(() => isLoading = false);
    }
  }

  Future<void> getLeaderboardPosition() async {
    try {
      final firebaseUser = _auth.currentUser;
      final firebaseUid = firebaseUser?.uid;

      if (firebaseUid == null) {
        print('No Firebase user logged in');
        setState(() => isLoading2 = false);
        return;
      }

      final leaderboard = await SupabaseService().getAllUsers();
      leaderboard.sort((a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0));

      final index = leaderboard.indexWhere((u) => u['firebase_uid'] == firebaseUid);

      setState(() {
        leaderboardPosition = index >= 0 ? index + 1 : -1;
        isLoading2 = false;
      });
    } catch (error) {
      print('Error fetching leaderboard: $error');
      setState(() => isLoading2 = false);
    }
  }

  final List<Widget> _pages = [
    Center(child: Text('', style: TextStyle(color: Colors.white))),
    Center(child: Text('', style: TextStyle(color: Colors.white))),
    Center(child: Text('', style: TextStyle(color: Colors.white))),
    Center(child: Text('', style: TextStyle(color: Colors.white))),
    Center(child: Text('', style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(' ', style: TextStyle(fontSize: 0, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFF2AC02),
        toolbarHeight: 60,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          if (!isLoading && curUser.isNotEmpty)
            Positioned(
              top: 55,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: curUser.map((user) {
                  final profileImg = _service.getAvatarUrl(user['firstname']);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.25),
                    child: ClipOval(
                      child: SizedBox(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        child: SvgPicture.network(
                          profileImg,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (!isLoading && curUser.isNotEmpty)
            Positioned(
              top: 310,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: curUser.map((user) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          '${user['firstname']} ${user['lastname']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Adumu',
                            fontSize: 27,
                          ),
                        ),
                        Text(
                          user['major']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Member Since ${user['created_at'].toString().split('T')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (!isLoading && !isLoading2 && curUser.isNotEmpty)
            Positioned(
              top: 430,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        (curUser[0]['points'] ?? 0).toString(),
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Adumu',
                          fontSize: 50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'POINTS',
                        style: TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Column(
                    children: [
                      Text(
                        leaderboardPosition.toString(),
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Adumu',
                          fontSize: 50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'LEADERBOARD',
                        style: TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Column(
                    children: [
                      Text(
                        (curUser[0]['events_attended'] ?? 0).toString(),
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Adumu',
                          fontSize: 50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'EVENTS',
                        style: TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Username, notifications, settings buttons
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 270),
            child: ElevatedButton(
              onPressed: () {
                print('username');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2AC02),
                textStyle: const TextStyle(fontFamily: 'Poppins'),
                fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
              ),
              child: const Text(
                'USERNAME',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 200),
            child: ElevatedButton(
              onPressed: () {
                print('notifications');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2AC02),
                textStyle: const TextStyle(fontFamily: 'Poppins'),
                fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
              ),
              child: const Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 130),
            child: ElevatedButton(
              onPressed: () {
                print('settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2AC02),
                textStyle: const TextStyle(fontFamily: 'Poppins'),
                fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
              ),
              child: const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _pages[_selectedIndex]),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
                child: CustomBottomNavBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
