import 'package:flutter/material.dart';
import 'package:shpeucfmobile/screens/Instagram.dart';
import 'package:shpeucfmobile/screens/leaderboard.dart';
import '../widgets/custom_bottom_nav_bar.dart'; // update if path differs
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/CodeScanner.dart';
import 'package:shpeucfmobile/screens/calendar.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/models/event.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }


  //This is how you will switch between pages from the dashboard (you need this logic on every other page as well)
  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CodeScanner()),
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
        Center(child: Landing()),
        Center(child: Shpestagram()),
        _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : CalendarPage(events: _events),
        CodeScanner(), // ✅ here!,
        Center(child: LeaderboardScreen()),
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
              padding: const EdgeInsets.only(left:20, right: 20, bottom: 25),
              child: CustomBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              )
            )
          ),

          //button placeholde
           //button placeholder
      
          // --- OLD LAYOUT ---
          // Column(
          // children: [
          //   Expanded(
          //     child: _pages[_selectedIndex]),
          //     Padding(
          //         padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
          //         child: CustomBottomNavBar(
          //         currentIndex: _selectedIndex,
          //         onTap: _onItemTapped,
          //         ),
          //     ),
          //   ],
          // ),
        //),
        ],
      ),
    );
  }
}
