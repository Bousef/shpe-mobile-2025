import 'package:flutter/material.dart';
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/CodeScanner.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';

class Admindashboard extends StatefulWidget {
  const Admindashboard({super.key});

  @override
  _AdmindashboardState createState() => _AdmindashboardState();
}

class _AdmindashboardState extends State<Admindashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Landing()),
    Center(
      child: Text('Instagram Page', style: TextStyle(color: Colors.white)),
    ),
    Center(child: Text('Calendar Page', style: TextStyle(color: Colors.white))),
    CodeScanner(),
    Center(child: Text('Members Page', style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
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
