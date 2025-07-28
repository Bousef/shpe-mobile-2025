import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shpeucfmobile/widgets/custom_bottom_nav_bar.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/widgets/reactionbutton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart'; 
import 'dart:ui';
import "package:shpeucfmobile/services/photo_service.dart";


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
   // _fetchProfile();
   // _fetchPosts();
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
  
  /*//USER PROFILE PICTURE
  Future<void> _fetchProfile() async { 
      final firebaseUser = _auth.currentUser;
      final firebaseUid = firebaseUser?.uid;
      
      if (firebaseUid == null || firebaseUid.isEmpty) {
        print('No Firebase user logged in. Cannot fetch profile image or username.');
        setState(() {
          userImageUrl = 'lib/images/topOfLeaderboard.svg'; // Fallback SVG
          currentUserName = 'Guest'; // Default username
          _isUserProfileLoading = false; // Set loading to false as we're done trying
        });
        return; // Exit the method early
      }
      
    try{

      final Map<String, dynamic> response = await supabase
      .from('profiles')
      .select('avatar_url, username')
      .eq('id',firebaseUid)
      .single();

    setState(() {
        userImageUrl=response['avatar_url']??'lib/images/topOfLeaderboard.svg';
        currentUserName = response['username'] ?? 'Unknown User';
        _isUserProfileLoading=false;
      });
    }
    catch(e){
      print('Error fetching user profile: $e');
      setState((){
        userImageUrl='lib/images/topOfLeaderboard.svg';
        currentUserName='Guest';
        _isUserProfileLoading=false;
      });
    }
   }

  //POST CONNECTION
  Future<void> _fetchPosts() async{
    try{
      final List<Map<String,dynamic>> data = await Supabase.instance.client
      .from('photos')
      .select('image_url,created_at, event(name), user(username)')
      .order('created_at', ascending: false)
      .limit(7);

      setState(() {
        _eventPosts=data;
      });
    }
   catch(e){
      print('Error fetching event post: $e');
      setState((){
      _eventPosts=[{
        'image_url':'lib/images/shpetest1.png',
        'event':{'name': 'Fallback Event'},
        'user':{'username': 'Guest'},
      },];
      });
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load posts.')),
    );
   }
  }*/

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 13), 
                  child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent, // optional: adds a border ring effect
                      child: ClipOval(
                          child: userImageUrl != null && userImageUrl!.startsWith('http')
                            ? Image.network(
                                userImageUrl!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              )
                            : SvgPicture.asset(
                                'lib/images/topOfLeaderboard.svg',
                                width: 30,
                                height: 30,
                              ),
                      ),
                    ),
                ),
              ),

            const SizedBox(width: 10),     
              Image.asset(
                'lib/images/SHPE2.png',
                height: 100,
              ),
            ],
          ),
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/images/background.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => Stack(
                                children:[
                                BackdropFilter( filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
                                child:Container(color: Colors.transparent,),
                                ),
                                 
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Center(
                                    child: PhotoView(
                                      imageProvider: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : const AssetImage('lib/images/shpetest1.png'),
                                      backgroundDecoration: const BoxDecoration(color: Colors.black),
                                    ),
                                  ),
                                ),
                                ],
                              ),
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
    );
  }
}
