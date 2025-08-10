import 'package:flutter/material.dart';
import 'dart:ui';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  PageController _pageController = PageController(initialPage: 0);
  DateTime _startMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _showEventPopup(DateTime date) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
            // Popup content
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Events on ${date.month}/${date.day}/${date.year}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        
                        Navigator.pop(context);
                      },
                      child: const Text('Go to Event A'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to EventDetailsPage
                        Navigator.pop(context);
                      },
                      child: const Text('Go to Event B'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTwoMonthPage(DateTime firstMonth) {
    return [
      _buildMonthCalendar(firstMonth),
      const SizedBox(height: 20),
      _buildMonthCalendar(DateTime(firstMonth.year, firstMonth.month + 1)),
    ];
  }

  Widget _buildMonthCalendar(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    int leadingEmptyDays = (firstDayOfMonth.weekday + 6) % 7; // Make Monday=0

    List<Widget> dayWidgets = [];

    // Weekday headers
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdayHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (d) => Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Text(
                d,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          )
          .toList(),
    );

    // Add leading empty slots before the 1st
    for (int i = 0; i < leadingEmptyDays; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add the days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(month.year, month.month, day);
      final isToday = currentDate.day == DateTime.now().day &&
          currentDate.month == DateTime.now().month &&
          currentDate.year == DateTime.now().year;

      dayWidgets.add(
        GestureDetector(
          onTap: () => _showEventPopup(currentDate),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? Colors.amber : null,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${_monthName(month.month)} ${month.year}',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          weekdayHeader,
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 11, //higher the number the less vertical padding
            children: dayWidgets,
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 255, 255, 255), // transparent
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final offset = index * 2;
          final targetMonth = DateTime(_startMonth.year, _startMonth.month + offset);
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset('lib/images/SHPE3.png', height: 80),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildTwoMonthPage(targetMonth)
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
