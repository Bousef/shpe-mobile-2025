import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:device_info_plus/device_info_plus.dart';

class EventPhotoGallery extends StatefulWidget {
  final String eventId; // UUID

  const EventPhotoGallery({super.key, required this.eventId});

  @override
  State<EventPhotoGallery> createState() => EventPhotoGalleryState();
}

class EventPhotoGalleryState extends State<EventPhotoGallery> {
  int currentPage = 0;
  final int itemsPerPage = 4;
  int refreshTrigger = 0;

  void refreshGallery() {
    setState(() {
      refreshTrigger++;
    });
  }

  // ---------------------------
  // Supabase fetching
  // ---------------------------
  Future<int> fetchTotalCount() async {
    final response = await Supabase.instance.client
        .from('photo')
        .select('id')
        .eq('eventID', widget.eventId);

    if (response is List) {
      return response.length;
    }
    return 0;
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

    return List<Map<String, dynamic>>.from(response);
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

  // ---------------------------
  // Download helpers
  // ---------------------------

  Future<int> _androidSdkInt() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<bool> _ensurePhotoPermissions() async {
    // iOS flow
    if (Platform.isIOS) {
      // 1) Check current status for add-only
      var status = await Permission.photosAddOnly.status;

      // Treat LIMITED as "good enough" (user gave limited library access; add-only still works for saving).
      if (status.isGranted || status.isLimited) return true;

      if (status.isPermanentlyDenied) {
        _showSettingsSnackBar('Photo access is permanently denied. Open Settings to allow.');
        return false;
      }

      // 2) Ask for add-only
      status = await Permission.photosAddOnly.request();
      if (status.isGranted || status.isLimited) return true;

      // 3) Older iOS fallback: try full photos if add-only isn’t supported/denied (rare)
      if (!status.isPermanentlyDenied) {
        var full = await Permission.photos.request();
        if (full.isGranted || full.isLimited) return true;
        if (full.isPermanentlyDenied) {
          _showSettingsSnackBar('Photo access is permanently denied. Open Settings to allow.');
        }
      } else {
        _showSettingsSnackBar('Photo access is permanently denied. Open Settings to allow.');
      }
      return false;
    }

    // Android flow
    if (Platform.isAndroid) {
      final sdk = await _androidSdkInt();

      // Android 13+ (API 33+): saving via MediaStore typically does NOT require runtime permission
      if (sdk >= 33) {
        return true;
      }

      // Android 10–12L (API 29–32) and below: request storage if needed
      final storage = await Permission.storage.status;
      if (storage.isGranted) return true;

      final res = await Permission.storage.request();
      if (res.isGranted) return true;

      if (res.isPermanentlyDenied) {
        _showSettingsSnackBar('Storage permission permanently denied. Open Settings to allow.');
      }
      return false;
    }

    // Other platforms (web/desktop) – allow silently
    return true;
  }

  void _showSettingsSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final ok = await _ensurePhotoPermissions();
      if (!ok) return;

      final resp = await http.get(Uri.parse(imageUrl));
      if (resp.statusCode != 200) {
        debugPrint('Failed to download image: ${resp.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Please try again.')),
          );
        }
        return;
      }

      // Write to a temp file first
      final tmpDir = await getTemporaryDirectory();
      final filename = 'event_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tmpDir.path}/$filename');
      await file.writeAsBytes(resp.bodyBytes);

      // Save to gallery
      final result = await ImageGallerySaver.saveFile(
        file.path,
        isReturnPathOfIOS: true, // iOS returns PH asset local identifier
      );

      final success = (result is Map &&
          (result['isSuccess'] == true ||
           result['is_success'] == true ||
           result['filePath'] != null ||
           result['file_path'] != null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Image saved to Photos.' : 'Failed to save image.')),
        );
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please try again.')),
        );
      }
    }
  }

  // ---------------------------
  // Fullscreen preview (no overflow)
  // ---------------------------
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Photo',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              // Full-screen zoomable image
              Positioned.fill(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
                  ),
                  loadingBuilder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.5,
                ),
              ),

              // Close button (top-right)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Download button (bottom-center)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _downloadImage(imageUrl);
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'Download',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      key: ValueKey(refreshTrigger),
      future: fetchTotalCount(),
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
              return const Center(child: Text('No photos uploaded yet.'));
            }

            // Responsive columns so tiles always fit screen and remain square
            return LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                int crossAxisCount = (maxWidth / 130).floor();
                crossAxisCount = crossAxisCount.clamp(2, 4);

                return Column(
                  mainAxisSize: MainAxisSize.min, // let Column size to content
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1, // square tiles
                      ),
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        final url = (photo['imgURL'] ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            if (url.isNotEmpty) {
                              _showFullScreenImage(context, url);
                            } else {
                              debugPrint('Photo URL missing.');
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.black12,
                              child: url.isEmpty
                                  ? const Center(child: Icon(Icons.broken_image))
                                  : Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(child: Icon(Icons.broken_image)),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Pager
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
                          style: const TextStyle(fontFamily: 'Poppins'),
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
      },
    );
  }
}
