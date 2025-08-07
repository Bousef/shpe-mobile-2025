import 'package:flutter/material.dart';
import 'package:shpeucfmobile/screens/Instagram.dart';
import '../widgets/custom_bottom_nav_bar.dart'; // update if path differs
import 'package:shpeucfmobile/landing.dart';
import 'package:shpeucfmobile/screens/CodeScanner.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();

}


class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;




  final List<Widget> _pages = [
    Center(child: Landing()),
    Center(child: Shpestagram()),
    Center(child: Text('Calendar Page', style: TextStyle(color: Colors.white))),
    CodeScanner(), // ✅ here!,
    Center(child: Text('Members Page', style: TextStyle(color: Colors.white))),
  ];

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
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          //button placeholde
           //button placeholder
      
          Column(
          children: [
            Expanded(
              child: _pages[_selectedIndex]),
              Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
                  child: CustomBottomNavBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
            ),
          ),
        ],
       ),
    
     //),
  ],

      ),
    );


 }
}