import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

class EventPhotoGallery extends StatefulWidget {
  final String eventId; // This should be a UUID string

  const EventPhotoGallery({super.key, required this.eventId});

  @override
  State<EventPhotoGallery> createState() => EventPhotoGalleryState();
}

//TODO: find a way to not have page entirely refresh every time u switch pages in photos
class EventPhotoGalleryState extends State<EventPhotoGallery> {
  int currentPage = 0;
  final int itemsPerPage = 4;
  int refreshTrigger = 0;

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Blurred background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),

              // Centered full-screen image
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: ClipRRect(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Close button
              // TODO: see if theres a way to get icon just above pic instead of hardcoded
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void refreshGallery() {
    setState(() {
      refreshTrigger++;
    });
  }

  @override
  void initState(){
    super.initState();
  }

  Future<List<Map<String, dynamic>>> fetchPhotos(int page) async {
    final start = page * itemsPerPage;
    final end = start + itemsPerPage - 1;

    final response = await Supabase.instance.client
        .from('photo')
        .select()
        .eq('eventID', widget.eventId)
        .order('created_at', ascending: false)
        .range(start, end);

    final photos = List<Map<String, dynamic>>.from(response);

    return photos;
  }

  void _nextPage(int totalCount) {
    final maxPage = (totalCount / itemsPerPage).ceil() - 1;
    if (currentPage < maxPage) {
      setState(() => currentPage++);
    }
  }

  void _prevPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
    }
  }

  Future<int> fetchTotalCount() async 
  {
    final response = await Supabase.instance.client
        .from('photo')
        .select('id')
        .eq('eventID', widget.eventId);

    if (response is List) {
      return response.length;
    } else {
      return 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: fetchTotalCount(),
      key: ValueKey(refreshTrigger),
      builder: (context, countSnapshot) {
        if (countSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalCount = countSnapshot.data ?? 0;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchPhotos(currentPage),
          builder: (context, photoSnapshot) {
            if (photoSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final photos = photoSnapshot.data ?? [];

            if (photos.isEmpty) {
              return const Center(child: Text("No photos uploaded yet."));
            }

            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return GestureDetector(
                      onTap: () {
                        final imgUrl = photo['imgURL'] as String?;
                        if(imgUrl != null && imgUrl.isNotEmpty) {
                          _showFullScreenImage(context, imgUrl);
                        } else {
                          print('photo has missing url or other error');
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photo['imgURL'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2AC02)),
                      onPressed: _prevPage,
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Page ${currentPage + 1} of ${(totalCount / itemsPerPage).ceil()}',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2AC02)),
                      onPressed: () => _nextPage(totalCount),
                      child: const Icon(Icons.arrow_forward, color: Colors.black),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
