import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/widgets/reactionbutton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart'; 
import 'dart:ui';
import "package:shpeucfmobile/services/photo_service.dart";
import 'package:shpeucfmobile/widgets/downloadbutton.dart';
import 'dart:async';


class Shpestagram extends StatefulWidget  {
  const Shpestagram({super.key});

  @override
  State<Shpestagram> createState() => _ShpestagramState();
}

class _ShpestagramState extends State<Shpestagram> {
  bool isLoading = true;
  int _selectedIndex = 1;
  
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient supabase = Supabase.instance.client;
  late final PhotoService service;

  String? userImageUrl;
  String? currentUserName;
  bool _isUserProfileLoading = true; 
  List<Map<String, dynamic>> _eventPosts = [];
  List<dynamic>? photos;

  @override
  void initState() {
    super.initState();
    service = PhotoService(supabase);
    _loadPhotos();
    //TEMPORARY DATA
    // TEMPORARY STATIC PROFILE DATA
    userImageUrl = 'lib/images/topOfLeaderboard.svg'; 
    currentUserName = 'TestUser';
    _eventPosts = [
    {
      'image_url': 'lib/images/test3.jpg',
      'event': {'name': 'Event'},
      'user': {'username': 'Guest'},
    },
    {
      'image_url': 'lib/images/shpetest1.png',
      'event': {'name': 'Another Event'},
      'user': {'username': 'AnotherUser'},
    },
    {
      'image_url': 'lib/images/testImage1.jpg',
      'event': {'name': 'Another Event'},
      'user': {'username': 'AnotherUser'},
    },
    
  ];
   
  }

  
  Future<void> _loadPhotos() async {
    try {
      photos = await service
          .fetchEventPhotosWithReactions('a8fb5b63-7193-4a6b-a4cb-0163b064ff78');

      // Print the fetched list for a quick smoke-test
      for (final p in photos!) {
        debugPrint(
            'Photo ${p.photoId} • uploader=${p.uploaderName} • reactions=${p.reactions}');
      }
    } catch (e) {
      debugPrint('Error fetching photos: $e');
    }
    setState(() {});  // refresh the UI
  }




  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/images/background.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('lib/images/SHPE3.png', height: 80)
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 15),
                    itemCount: photos?.length ?? 0,
                    itemBuilder: (context, index) {
                      final photo = photos![index];                 
                      final imageUrl   = photo.imgUrl;
                      final username   = photo.uploaderName ?? 'Guest';
                      final eventName  = 'Event';
                      final reactions = photo.reactions ?? 0; // implement reactions later
                      // final eventName = _eventPosts[index]['event']['name'] ?? 'Unknown Event';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                eventName,
                                style: TextStyle(
                                  color: Color(0xFFF2AC02),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            GestureDetector(
                              onTap: () async {
                                double aspectRatio = 1; // fallback
                  
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
                              },
                  
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
                  
                            
                            Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              margin: const EdgeInsets.only(top: 4, left: 25, right: 25),
                              alignment: Alignment.centerRight,
                              child: Text(
                                username,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF2AC02),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                  
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.075, // centers the 85% width
                              ),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.7,
                              ),
                            ),
                  
                  
                            Padding(
                              padding: const EdgeInsets.only(left: 38.0, top: 2.0, bottom: 20.0),
                              child: const ReactionButton(),
                            ),                      
                          ],
                        ),
                      );
                    },
                        ),
                ),
              ],
            ),
    ),
  ],
),
    );
  }
}
