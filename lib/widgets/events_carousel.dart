import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/screens/eventdetails.dart';



/// ──────────── CAROUSEL WIDGET ─────────────────────────────────────────────────────
class EventsCarousel extends StatefulWidget {
  final List<Event> events;
  const EventsCarousel({super.key, required this.events});

  @override
  State<EventsCarousel> createState() => _EventsCarouselState();
}

class _EventsCarouselState extends State<EventsCarousel> {
  final _controller = PageController(viewportFraction: .75);
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    _page = _controller.initialPage.toDouble();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.events.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final delta = (_page - index).abs();
          final scale = 1 - (delta * 0.15).clamp(0.0, 1.0);
          final blurSigma = (delta * 4).clamp(0.0, 4.0);

          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () { // your part here Daniel
                // TODO: push to EventDetailsPage(event: widget.events[index]);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventDetailsPage(event: widget.events[index]),
                  )
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(widget.events[index].imageUrl,
                          fit: BoxFit.cover),
                      if (blurSigma > 0)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                                sigmaX: blurSigma, sigmaY: blurSigma),
                            child: const SizedBox(),
                          ),
                        ),
                        
                      // ----gradient and title on event cards
                      // ----keeping here for now just in case
                      // Align(
                      //   alignment: Alignment.bottomCenter,
                      //   child: Container(
                      //     height: 60,
                      //     decoration: const BoxDecoration(
                      //       gradient: LinearGradient(
                      //         begin: Alignment.topCenter,
                      //         end: Alignment.bottomCenter,
                      //         colors: [Colors.transparent, Colors.black54],
                      //       ),
                      //     ),
                      //     child: Center(
                      //       child: Text(
                      //         widget.events[index].name,
                      //         style: const TextStyle(
                      //             color: Colors.white, fontSize: 16),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
