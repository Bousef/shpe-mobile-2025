import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventPhotoGallery extends StatefulWidget {
  final String eventId; // This should be a UUID string

  const EventPhotoGallery({super.key, required this.eventId});

  @override
  State<EventPhotoGallery> createState() => _EventPhotoGalleryState();
}

class _EventPhotoGalleryState extends State<EventPhotoGallery> {
  int currentPage = 0;
  final int itemsPerPage = 4;

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
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo['imgURL'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _prevPage,
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 20),
                    Text('Page ${currentPage + 1} of ${(totalCount / itemsPerPage).ceil()}'),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => _nextPage(totalCount),
                      child: const Icon(Icons.arrow_forward),
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
