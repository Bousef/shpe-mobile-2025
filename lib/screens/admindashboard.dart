import 'package:flutter/material.dart';
import 'package:shpeucfmobile/screens/Instagram.dart';
import 'package:shpeucfmobile/screens/leaderboard.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/CodeScanner.dart'; // kept so pages list stays identical
import 'package:shpeucfmobile/screens/calendar.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/screens/CreateEvent.dart';
class Admindashboard extends StatefulWidget {
  const Admindashboard({super.key});

  @override
  State<Admindashboard> createState() => _AdmindashboardState();
}

class _AdmindashboardState extends State<Admindashboard> {
  int _selectedIndex = 0;
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final supabaseService = SupabaseService();
    final events = await supabaseService.fetchAllEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  // Same as student, but index 3 pushes CreateEvent.
  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateEvent()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const Center(child: Landing()),
      const Center(child: Shpestagram()),
      _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : CalendarPage(events: _events),
      const CodeScanner(), // keep a widget here so indices match your student view
      const Center(child: LeaderboardScreen()),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          pages[_selectedIndex],
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
              child: CustomBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
