import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchUsersSortedByPoints();
  }

  Future<void> fetchUsersSortedByPoints() async {
    final supabase = Supabase.instance.client;

    try {
      final List data = await supabase
          .from('users')
          .select('firstname, points')
          .order('points', ascending: false);

      setState(() {
        users = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching users: $error');
      setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'lib/images/background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(color: Colors.black.withOpacity(0.4)),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // const SizedBox(height: 80),
            
                // Top logos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(),
                ),
                // Centered Leaderboard banner
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: SHPEHeaderText(text: 'Leaderboard')),
                ),
            
                const SizedBox(height: 10),
                // User list or loading
                Expanded(
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : users.isEmpty
                          ? const Center(
                            child: Text(
                              'No users found.',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                color: Colors.white.withOpacity(0.95),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(
                                    user['firstname'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    user['points'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
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
