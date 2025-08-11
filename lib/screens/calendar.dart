import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/screens/eventdetails.dart';

class CalendarPage extends StatefulWidget {
  final List<Event> events;

  const CalendarPage({super.key, required this.events});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  PageController _pageController = PageController(initialPage: 0);
  DateTime _startMonth = DateTime(DateTime.now().year, DateTime.now().month);


  void _showEventPopup(DateTime selectedDay, List<Event> eventsForDay) {
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
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.5,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Events on ${selectedDay.month}/${selectedDay.day}/${selectedDay.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: eventsForDay.isEmpty
                          ? const Center(
                              child: Text(
                                'No events scheduled.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: eventsForDay.length,
                              itemBuilder: (context, index) {
                                final event = eventsForDay[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EventDetailsPage(event: event),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(12),
                                      backgroundColor: Color(0xFFF2AC02),
                                    ),
                                    child: Text(
                                      event.name,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color.fromARGB(255, 24, 43, 113),
                          decoration: TextDecoration.underline,
                          fontSize: 15,
                        )
                      ),
                    )
                  ],
                ),
              ),
            ),
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
    int leadingEmptyDays = (firstDayOfMonth.weekday + 6) % 7;

    List<Widget> dayWidgets = [];

    // weekday headers
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdayHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (d) => Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
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

    // add leading empty slots before the 1st
    for (int i = 0; i < leadingEmptyDays; i++) {
      dayWidgets.add(const SizedBox());
    }

    // add the days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(month.year, month.month, day);
      final isToday = currentDate.day == DateTime.now().day &&
          currentDate.month == DateTime.now().month &&
          currentDate.year == DateTime.now().year;

      // filter events by selected date
      final eventsForDay = widget.events.where((event) {
        return event.date != null &&
            event.date!.year == currentDate.year &&
            event.date!.month == currentDate.month &&
            event.date!.day == currentDate.day;
      }).toList();

      final dotCount = eventsForDay.length.clamp(0, 3);

      dayWidgets.add(
        GestureDetector(
          onTap: () => _showEventPopup(currentDate, eventsForDay),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
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
              const SizedBox(height: 1),
              if (dotCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(dotCount, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 24, 43, 113),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                )
            ],
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
            crossAxisSpacing: 11,
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
