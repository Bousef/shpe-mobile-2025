import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

int _selectedIndex = 0;

final List<Widget> _pages = [
  Center(child: Text('', style: TextStyle(color: Colors.white))),
  Center(child: Text('', style: TextStyle(color: Colors.white))),
  Center(child: Text('', style: TextStyle(color: Colors.white))),
  Center(child: Text('', style: TextStyle(color: Colors.white))),
  Center(child: Text('', style: TextStyle(color: Colors.white))),
];

class _NotificationsState extends State<Notifications> {

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

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
