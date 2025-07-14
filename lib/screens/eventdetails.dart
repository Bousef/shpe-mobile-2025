import 'package:flutter/material.dart';
import 'package:shpeucfmobile/models/event.dart';


class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  String formatDate(DateTime date) {
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final weekday = weekdayNames[date.weekday - 1];
    final month = twoDigits(date.month);
    final day = twoDigits(date.day);
    final year = date.year.toString();

    return '$weekday, $month/$day/$year';
  }

  String formatTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.name,
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Poppins',
          )
        ),
        backgroundColor: const Color(0xFFF2AC02),
        toolbarHeight: 60,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  event.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),

                //Event Details
                LayoutBuilder(
                  builder:(context, constraints) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final whiteBgHeight = screenHeight - 200 - kToolbarHeight - 90;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        constraints: BoxConstraints(minHeight: whiteBgHeight),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (event.date != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Date: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: formatDate(event.date!),
                                      ),
                                    ] 
                                  )
                                )
                              ),
                            if (event.time != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Time: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: formatTime(event.time!),
                                      ),
                                    ] 
                                  )
                                )
                              ),
                            if (event.location != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Location: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: event.location ?? 'No location found.',
                                      ),
                                    ] 
                                  )
                                )
                              ),
                            if (event.description != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Description: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: event.description ?? 'No description found.',
                                      ),
                                    ] 
                                  )
                                )
                              ),
                            if (event.pointsWorth != null)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Points: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: '${event.pointsWorth}',
                                      ),
                                    ]
                                  )
                                )
                              )
                          ]
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ]
      ),
    );
  }
}
