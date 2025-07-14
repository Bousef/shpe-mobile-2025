import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  late final SupabaseService _service;

  @override
  void initState() {
    super.initState();
    _service = SupabaseService();
    fetchUsers();
    getLeaderboardPosition();
  }

  Future<void> fetchUsers() async {
    final supabase = Supabase.instance.client;
    try {
      final user = supabase.auth.currentUser;
      final userId = user?.id;

      print(userId);

      if (userId == null) {
        print('No user logged in');
        return;
      }

      final List userInfo =
          await Supabase.instance.client
              .from('users')
              .select(
                'firstname, lastname, points, created_at, events_attended, major',
              )
              .eq('id', userId)
              .single();

      setState(() {
        curUser = List<Map<String, dynamic>>.from(userInfo);
        isLoading = false;
        print('curUser = $curUser');
      });
    } catch (error) {
      print('Error fetching users: $error');
      setState(() => isLoading = false);
    }
  }

  Future<void> getLeaderboardPosition() async {
    final supabase = Supabase.instance.client;
    try {
      final user = supabase.auth.currentUser;
      final userId = user?.id;

      print(userId);

      if (userId == null) {
        print('No user logged in');
        return;
      }

      final List leaderboard = await supabase
          .from('users')
          .select('id, points')
          .order('points', ascending: false);

      print(leaderboard);
      final index = leaderboard.indexWhere((u) => u['id'] == userId);

      print(index);

      setState(() {
        leaderboardPosition = index >= 0 ? index + 1 : -1;
        isLoading2 = false;
      });
    } catch (error) {
      print('Error fetching users: $error');
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
                children: List.generate(curUser.length, (index) {
                  final user = curUser[index];
                  final profileImg = _service.getAvatarUrl(user['firstname']);

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.25,
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        child: SvgPicture.network(
                          profileImg,
                          fit: BoxFit.cover,
                        ),
                      ), //make a circle
                    ),
                  );
                }),
              ),
            ),
          //spot for username, name, date started
          if (!isLoading && curUser.isNotEmpty)
            Positioned(
              top: 310,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(curUser.length, (index) {
                  final user = curUser[index];

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          user['firstname'].toString() +
                              ' ' +
                              user['lastname'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Adumu',
                            fontSize: 27,
                          ),
                        ),
                        Text(
                          user['major'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Member Since ' +
                              user['created_at'].toString().split('T')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          //spot for points, leaderboard position, and events attended
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
                        curUser[0]['points'].toString(),
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Adumu',
                          fontSize: 50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'POINTS',
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 50),
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
                      Text(
                        'LEADERBOARD',
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 50),
                  Column(
                    children: [
                      Text(
                        curUser[0]['events'].toString(),
                        style: const TextStyle(
                          color: Color(0xFFF2AC02),
                          fontFamily: 'Adumu',
                          fontSize: 50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EVENTS',
                        style: const TextStyle(
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
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 270),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('username');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2AC02),
                    textStyle: const TextStyle(fontFamily: 'Poppins'),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
                  ),
                  child: Text(
                    'USERNAME',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 200),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('notifications');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2AC02),
                    textStyle: const TextStyle(fontFamily: 'Poppins'),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
                  ),
                  child: Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 130),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('settings');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2AC02),
                    textStyle: const TextStyle(fontFamily: 'Poppins'),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    fixedSize: Size(MediaQuery.sizeOf(context).width - 20, 50),
                  ),
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          //----------Navbar----------
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
