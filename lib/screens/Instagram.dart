import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shpeucfmobile/services/photo_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/downloadbutton.dart';
// import 'package:shpeucfmobile/widgets/reactionbutton.dart'; // removed
import 'package:shpeucfmobile/models/event.dart';

class _PhotoVM {
  final String photoId;
  final String imgUrl;
  final String? uploaderName;
  final int reactions; // kept but unused; safe to remove if you want

  _PhotoVM({
    required this.photoId,
    required this.imgUrl,
    required this.uploaderName,
    required this.reactions,
  });
}

class Shpestagram extends StatefulWidget {
  const Shpestagram({super.key});

  @override
  State<Shpestagram> createState() => _ShpestagramState();
}

class _ShpestagramState extends State<Shpestagram> {
  final SupabaseClient supabase = Supabase.instance.client;

  late final PhotoService _photoService;
  late final SupabaseService _supabaseService;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedEventId = 'ALL';

  List<Event> _events = [];
  List<_PhotoVM> _visiblePhotos = [];

  @override
  void initState() {
    super.initState();
    _photoService = PhotoService(supabase);
    _supabaseService = SupabaseService();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      // 1) Load events for the dropdown
      _events = await _supabaseService.fetchAllEvents();

      // 2) Default feed: pull ALL photos (loop events and combine)
      _visiblePhotos = await _fetchAllPhotosAcrossEvents();
    } catch (e) {
      debugPrint('Shpestagram init error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<_PhotoVM>> _fetchAllPhotosAcrossEvents() async {
    final List<_PhotoVM> all = [];
    for (final e in _events) {
      final raw = await _photoService.fetchEventPhotosWithReactions(e.id);
      all.addAll(raw.map((p) {
        final int reactionsCount = (p.reactions is int)
            ? p.reactions as int
            : int.tryParse('${p.reactions}') ?? 0;
        return _PhotoVM(
          photoId: p.photoId.toString(),
          imgUrl: (p.imgUrl ?? '').toString(),
          uploaderName: p.uploaderName,
          reactions: reactionsCount,
        );
      }));
    }
    // optional: newest first if your id is time-based
    all.sort((a, b) => b.photoId.compareTo(a.photoId));
    return all;
  }

  Future<List<_PhotoVM>> _fetchPhotosForEvent(String eventId) async {
    final raw = await _photoService.fetchEventPhotosWithReactions(eventId);
    final list = raw.map((p) {
      final int reactionsCount = (p.reactions is int)
          ? p.reactions as int
          : int.tryParse('${p.reactions}') ?? 0;
      return _PhotoVM(
        photoId: p.photoId.toString(),
        imgUrl: (p.imgUrl ?? '').toString(),
        uploaderName: p.uploaderName,
        reactions: reactionsCount,
      );
    }).toList();

    // optional: newest first
    list.sort((a, b) => b.photoId.compareTo(a.photoId));
    return list;
  }

  Future<void> _onSelectEvent(String id) async {
    setState(() {
      _selectedEventId = id;
      _isLoading = true;
    });
    try {
      if (id == 'ALL') {
        _visiblePhotos = await _fetchAllPhotosAcrossEvents();
      } else {
        _visiblePhotos = await _fetchPhotosForEvent(id);
      }
    } catch (e) {
      debugPrint('Select event error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      if (_selectedEventId == 'ALL') {
        _visiblePhotos = await _fetchAllPhotosAcrossEvents();
      } else {
        _visiblePhotos = await _fetchPhotosForEvent(_selectedEventId);
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/images/background.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('lib/images/SHPE3.png', height: 80),
                ),

                _buildEventDropdown(),
                const SizedBox(height: 8),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildPhotoList(_visiblePhotos),
                  ),
                ),

                if (_isRefreshing) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDropdown() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'ALL', child: Text('All events')),
      ..._events.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
    ];

    final validValue = items.any((it) => it.value == _selectedEventId)
        ? _selectedEventId
        : 'ALL';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2AC02).withOpacity(0.6)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: validValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E1E),
            iconEnabledColor: const Color(0xFFF2AC02),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            items: items,
            onChanged: (value) async {
              if (value == null) return;
              await _onSelectEvent(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoList(List<_PhotoVM> photos) {
    if (photos.isEmpty) {
      return const Center(
        child: Text('No photos yet.', style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.builder(
      key: ValueKey(_selectedEventId),
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: photos.length,
      itemBuilder: (context, index) => _buildPhotoCard(photos[index]),
    );
  }

  Widget _buildPhotoCard(_PhotoVM photo) {
    final imageUrl = photo.imgUrl;
    final username = photo.uploaderName ?? 'Guest';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openZoom(context, imageUrl),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Image.asset('lib/images/shpetest1.png', fit: BoxFit.cover),
              ),
            ),
          ),

          // Username (right aligned)
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.only(top: 4, left: 25, right: 25),
            alignment: Alignment.centerRight,
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2AC02),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.075,
            ),
            child: const Divider(color: Colors.grey, thickness: 0.7),
          ),
          // Removed reactions + inline download row
        ],
      ),
    );
  }

  Future<void> _openZoom(BuildContext context, String imageUrl) async {
    double aspectRatio = 1;
    try {
      final ImageProvider provider = imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : const AssetImage('lib/images/shpetest1.png') as ImageProvider;

      final completer = Completer<Size>();
      final stream = provider.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ));
        }),
      );

      final size = await completer.future;
      aspectRatio = size.width / size.height;
    } catch (_) {}

    if (!mounted) return;

    // Overlay with download button ONLY here
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {},
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
                            maxScale:
                                PhotoViewComputedScale.covered * 4.0,
                            initialScale:
                                PhotoViewComputedScale.contained,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Downloadbutton(imageUrl: imageUrl), // ✅ only here
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
