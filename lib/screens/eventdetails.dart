import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shpeucfmobile/models/event.dart';
import 'package:shpeucfmobile/widgets/event_photo_gallery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:shpeucfmobile/widgets/shpe_header_text.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {

  final GlobalKey<EventPhotoGalleryState> galleryKey = GlobalKey();
  final supabase = Supabase.instance.client;

  Future<void> _pickAndUploadImages(String eventId) async {
    final ImagePicker picker = ImagePicker();

    //pick multiple images
    final List<XFile>? images = await picker.pickMultiImage();

    if (images == null || images.isEmpty) return;

    // get firebase user
    final firebaseUser = FirebaseAuthService().getCurrentUser();
    //debug
    print('Current firebase user: $firebaseUser');
    if (firebaseUser == null) {
      print('⚠️ No firebase user logged in! Aborting upload.');
      return;
    }

    //get supabase user using firebase uid
    final firebaseUid = firebaseUser.uid;
    final userRow = await SupabaseService().getUserByFirebaseUid(firebaseUid);
    //debug
    if (userRow == null) {
      print('⚠️ No matching user in Supabase with Firebase UID: $firebaseUid');
      return;
    }

    final userId = userRow['firebase_uid'];
    // print('supabase user ID: $userId');

    for(final image in images) {
      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final filePath = 'photo/$eventId/$fileName';

      try {
        //upload to supabase storage
        final storageResponse = await supabase.storage
          .from('event-photos')
          .uploadBinary(filePath, bytes);

        final imgURL = supabase.storage
          .from('event-photos')
          .getPublicUrl(filePath);

        //insert into photo table
        await supabase.from('photo').insert({
          'eventID': eventId,
          'userID': userId ?? 'anonymous',
          'imgURL': imgURL,
        });

        galleryKey.currentState?.refreshGallery();

        // print('uploaded image: $fileName');
      } catch (e) {
        print('Upload error: $e');
      }
    }
  }

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
          widget.event.name,
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
                  widget.event.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),

            //------ EVENT DETAILS ------
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    widget.event.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (widget.event.date != null)
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
                                          const TextSpan(
                                            text: 'Date: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: formatDate(widget.event.date!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.event.time != null)
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
                                          const TextSpan(
                                            text: 'Time: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: formatTime(widget.event.time!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.event.location != null)
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
                                          const TextSpan(
                                            text: 'Location: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: widget.event.location ?? 'No location found.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.event.description != null)
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
                                          const TextSpan(
                                            text: 'Description: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: widget.event.description ?? 'No description found.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.event.pointsWorth != null)
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
                                          const TextSpan(
                                            text: 'Points: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: '${widget.event.pointsWorth}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
                          //----- PHOTOS -----
                            //this is temporary until either i figure out font
                            //    or get image
                            SHPEHeaderText(text: 'PHOTOS', fontSize: 40),
                            SizedBox(height: 5),

                            EventPhotoGallery(
                              key: galleryKey,
                              eventId: widget.event.id,
                            ),

                          //------ UPLOAD PHOTOS BUTTON ------
                            Padding(
                              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                              child: Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // function to upload buttons here
                                    await _pickAndUploadImages(widget.event.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 9, 39, 98),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        SizedBox(width: 10),
                                        const Text(
                                          'UPLOAD PHOTOS',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
