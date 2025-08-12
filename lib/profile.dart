import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;
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

      final userInfo = await _service.client
          .from('users')
          .select('firstname, lastname, points, created_at, events_attended, major')
          .eq('firebase_uid', firebaseUid)
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

      final leaderboard = await _service.getAllUsers();
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

  final List<Widget> _pages = List.generate(
    5,
    (_) => const Center(child: Text('', style: TextStyle(color: Colors.white))),
  );

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(' ', style: TextStyle(fontSize: 0, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFF2AC02),
        toolbarHeight: 60,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          if (!isLoading && curUser.isNotEmpty)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: curUser.map((user) {
                      final profileImg = _service.getAvatarUrl(user['firstname']);
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.25),
                        child: ClipOval(
                          child: SizedBox(
                            width: screenWidth * 0.5,
                            height: screenWidth * 0.5,
                            child: SvgPicture.network(profileImg, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 15),
                  _buildUserInfo(),
                  const SizedBox(height: 15),
                  if (!isLoading2)
                    _buildStatsRow(),
                    const SizedBox(height: 30),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildActionButton('USERNAME', 10),
                      _buildActionButton('NOTIFICATIONS', 10),
                      _buildActionButton('SETTINGS', 10),
                    ],
                  ),
                ],
              ),
            ),
          //   Positioned(
          //     top: 55,
          //     left: 0,
          //     right: 0,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: curUser.map((user) {
          //         final profileImg = _service.getAvatarUrl(user['firstname']);
          //         return Padding(
          //           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.25),
          //           child: ClipOval(
          //             child: SizedBox(
          //               width: screenWidth * 0.5,
          //               height: screenWidth * 0.5,
          //               child: SvgPicture.network(profileImg, fit: BoxFit.cover),
          //             ),
          //           ),
          //         );
          //       }).toList(),
          //     ),
          //   ),
          // if (!isLoading && curUser.isNotEmpty)
          //   Positioned(
          //     top: 310,
          //     left: 0,
          //     right: 0,
          //     child: _buildUserInfo(),
          //   ),
          // if (!isLoading && !isLoading2 && curUser.isNotEmpty)
          //   Positioned(
          //     top: 430,
          //     left: 0,
          //     right: 0,
          //     child: _buildStatsRow(),
          //   ),
          // _buildActionButton('USERNAME', 270),
          // _buildActionButton('NOTIFICATIONS', 200),
          // _buildActionButton('SETTINGS', 130),
          // Column(
          //   children: [
          //     Expanded(child: _pages[_selectedIndex]),
          //     Padding(
          //       padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
          //       child: CustomBottomNavBar(
          //         currentIndex: _selectedIndex,
          //         onTap: _onItemTapped,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
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
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStat((curUser[0]['points'] ?? 0).toString(), 'POINTS'),
        const SizedBox(width: 50),
        _buildStat(leaderboardPosition.toString(), 'LEADERBOARD'),
        const SizedBox(width: 50),
        _buildStat((curUser[0]['events_attended'] ?? 0).toString(), 'EVENTS'),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF2AC02),
            fontFamily: 'Adumu',
            fontSize: 50,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF2AC02),
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, double bottomPadding) {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ElevatedButton(
        onPressed: () {
          print(label.toLowerCase());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF2AC02),
          textStyle: const TextStyle(fontFamily: 'Poppins'),
          fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
