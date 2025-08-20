import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:shpeucfmobile/widgets/downloadbutton.dart';
import 'dart:async';

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

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Ask for permission (Android)
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        print('storage permission denied');
        return;
      }

      // Download image data
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('failed to download image');
        return;
      }

      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        quality: 100,
        name: "event_photo_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!result['isSuccess']) {
        print("Failed to save image: $result");
      }
    } catch (e) {
      print('Download failed: $e');
    }
  }


  Future<void> _showFullScreenImage(BuildContext context, String imageUrl) async {
    double aspectRatio = 1; //fallback

    // Get actual image dimensions
    try {
      final ImageProvider provider = imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : const AssetImage('lib/images/shpetest1.png') as ImageProvider;

      final completer = Completer<Size>();
      final stream = provider.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }),
      );

      final size = await completer.future;
      aspectRatio = size.width / size.height;
    } catch (_) {}

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return Stack(
            children: [
              // Single tap anywhere on background closes
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),

              // Photo + download button centered vertically
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {}, // prevent close when tapping photo
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                          maxWidth: MediaQuery.of(context).size.width * 0.95,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: PhotoView(
                            imageProvider: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : const AssetImage('lib/images/shpetest1.png')
                                    as ImageProvider,
                            backgroundDecoration:
                                const BoxDecoration(color: Colors.transparent),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 4.0,
                            initialScale: PhotoViewComputedScale.contained,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Downloadbutton(imageUrl: imageUrl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
