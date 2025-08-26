import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/screens/homescreen.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  int _selectedIndex = 2;
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDescriptionController = TextEditingController();
  final TextEditingController eventDateController = TextEditingController();
  final TextEditingController eventTimeController = TextEditingController();
  final TextEditingController eventPointsController = TextEditingController();
  final TextEditingController eventLocationController = TextEditingController();
  final TextEditingController eventUrlController = TextEditingController();

  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  bool _isCreatingEvent = false;

  Uint8List? _flyer;
  Uint8List? qrImageBytes;
  String? _eventName = '';
  bool _isSuccess = false;
  String? _dropdownValue = 'GBM';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  pickImage(ImageSource source) async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? _file = await _imagePicker.pickImage(source: source);
    if (_file != null) return await _file.readAsBytes();
    print('No image selected');
  }

  Future selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);
    setState(() {
      _flyer = img;
    });
  }

  Future<void> updateQR(String newName) async {
    _eventName = newName;

    final qrValidationResult = QrValidator.validate(
      data: _eventName!,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      final image = await painter.toImage(512);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      setState(() {
        qrImageBytes = bytes;
      });
    }
  }

  /// Save QR to Photos/Gallery with proper OS-specific permissions.
  Future<void> _saveQrToGallery() async {
    if (qrImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate the QR code first.')),
      );
      return;
    }

    // Request the right permission per platform / OS
    Future<bool> _requestPhotosPermission() async {
      if (Platform.isAndroid) {
        // On Android 13+ permission_handler maps Permission.photos to READ_MEDIA_IMAGES
        final photos = await Permission.photos.request();
        if (photos.isGranted) return true;

        // Fallback for older Android versions (READ/WRITE storage)
        final storage = await Permission.storage.request();
        if (storage.isGranted) return true;

        return false;
      } else if (Platform.isIOS) {
        // Prefer Add-Only; fall back to Photos if needed
        final addOnly = await Permission.photosAddOnly.request();
        if (addOnly.isGranted) return true;

        final photos = await Permission.photos.request();
        return photos.isGranted;
      } else {
        // Other platforms – let GallerySaver attempt; generally unsupported
        return true;
      }
    }

    final granted = await _requestPhotosPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Enable Photos access in Settings.')),
      );
      return;
    }

    try {
      // Write PNG to a temp file
      final tempDir = await getTemporaryDirectory();
      final filename = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(qrImageBytes!, flush: true);

      // Save to gallery / Photos (Android: DCIM album helps visibility)
      final bool? result = await GallerySaver.saveImage(
        file.path,
        albumName: 'SHPE UCF',
        toDcim: true,
      );

      if (result == true) {
        setState(() => _isSuccess = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR saved to gallery.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save image.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR: $e')),
      );
    }
  }

  Future<void> _createEvent() async {
    // Validate required fields
    if (eventNameController.text.trim().isEmpty ||
        eventDescriptionController.text.trim().isEmpty ||
        eventDateController.text.trim().isEmpty ||
        eventTimeController.text.trim().isEmpty ||
        eventPointsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      setState(() {
        _isCreatingEvent = true;
      });

      // Get current user
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user ID from Supabase
      final userId = await _supabaseService.getUserIdByFirebaseUid(currentUser.uid);

      // Parse points
      final points = int.tryParse(eventPointsController.text.trim());
      if (points == null) {
        throw Exception('Invalid points value');
      }

      // Upload image if available
      String? imageUrl;
      if (_flyer != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${eventNameController.text.trim().replaceAll(' ', '_')}_$timestamp.png';
        imageUrl = await _supabaseService.uploadEventImage(_flyer!, fileName);
      }

      // Create the event
      await _supabaseService.createEvent(
        name: eventNameController.text.trim(),
        description: eventDescriptionController.text.trim(),
        eventDate: eventDateController.text.trim(),
        eventTime: eventTimeController.text.trim(),
        pointsWorth: points,
        createdBy: userId,
        location: eventLocationController.text.trim().isEmpty 
            ? null : eventLocationController.text.trim(),
        eventUrl: eventUrlController.text.trim().isEmpty 
            ? null : eventUrlController.text.trim(),
        imageUrl: imageUrl, // Now includes the uploaded image URL
        qrCodeUrl: _eventName, // Using the QR code data as URL for now
      );

      // Show success, then return to previous screen (dashboard)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingEvent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('lib/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Column(
                      //creates input fields for the event
                      children: [
                        // Header AppBar WITHOUT back arrow
                        AppBar(
                          automaticallyImplyLeading: false,
                          leading: const SizedBox.shrink(), // render nothing
                          title: const SHPEHeaderText(text: 'CREATE EVENT'),
                          titleSpacing: 0,
                          centerTitle: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                        ),
                        const SizedBox(height: 25),
                        InputField(text: 'Name', controller: eventNameController),
                        const SizedBox(height: 25),
                        InputField(text: 'Description', controller: eventDescriptionController),
                        const SizedBox(height: 25),
                        // Date picker
                        TextField(
                          controller: eventDateController,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              String formatted =
                                  "${pickedDate.year.toString()}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              eventDateController.text = formatted;
                            }
                          },
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F3F7),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.all(Radius.circular(30.0)),
                            ),
                            hintText: "Event Date (YYYY-MM-DD)",
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(height: 25),
                        InputField(text: 'Time (00:00)', controller: eventTimeController),
                        const SizedBox(height: 25),

                        // Dropdown menu for event type
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                          ),
                          height: 60,
                          child: DropdownMenu(
                            onSelected: (value) {
                              if (value != null) {
                                setState(() {
                                  _dropdownValue = value;
                                });
                              }
                            },
                            label: const Text('Event Type'),
                            textAlign: TextAlign.start,
                            trailingIcon: const Icon(Icons.arrow_drop_down),
                            width: 415,
                            initialSelection: _dropdownValue,
                            enableFilter: true,
                            enableSearch: true,
                            menuStyle: MenuStyle(
                              backgroundColor: const WidgetStatePropertyAll(Colors.white),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.transparent, width: 1.5),
                                ),
                              ),
                            ),
                            dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                              DropdownMenuEntry<String>(value: 'GBM', label: 'GBM'),
                              DropdownMenuEntry<String>(value: 'Tech', label: 'Tech'),
                              DropdownMenuEntry<String>(value: 'Pro-Dev', label: 'Pro-Dev'),
                              DropdownMenuEntry<String>(value: 'MentorSHPE', label: 'MentorSHPE'),
                              DropdownMenuEntry<String>(value: 'Projects', label: 'Projects'),
                              DropdownMenuEntry<String>(value: 'SHPEtinas', label: 'SHPEtinas'),
                              DropdownMenuEntry<String>(value: 'Outreach', label: 'Outreach'),
                            ],
                            textStyle: const TextStyle(
                              color: Color(0xFF424242),
                            ),
                            inputDecorationTheme: const InputDecorationTheme(
                              border: InputBorder.none, // removes the default border
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        InputField(text: 'Points', controller: eventPointsController),
                        const SizedBox(height: 25),
                        InputField(text: 'Location (Optional)', controller: eventLocationController),
                        const SizedBox(height: 25),
                        InputField(text: 'Event URL (Optional)', controller: eventUrlController),
                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: selectImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                label: const Text('Upload Flyer', style: TextStyle(color: Colors.white, fontSize: 20)),
                                icon: const Icon(Icons.upload_file, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _flyer != null
                                  ? const Icon(Icons.check, color: Colors.green, size: 30)
                                  : const SizedBox(height: 0),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _flyer != null
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.memory(_flyer!, fit: BoxFit.cover),
                                ),
                              )
                            : const SizedBox(height: 0),

                        const SizedBox(height: 20),

                        // QR CODE GENERATOR SECTION
                        Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final eventName = eventNameController.text;
                                  if (eventName.isNotEmpty) {
                                    updateQR(eventName); // generates the qr code and image is stored as bytes
                                  }
                                },
                                icon: const Icon(Icons.qr_code, color: Colors.white, size: 20),
                                label: const Text('Generate QR Code', style: TextStyle(color: Colors.white, fontSize: 20)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 48,
                                width: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _saveQrToGallery,   // <-- fixed: use robust saver
                                  label: const Text('Download', style: TextStyle(color: Colors.transparent)),
                                  icon: Icon(
                                    _isSuccess ? Icons.check : Icons.download,
                                    color: _isSuccess ? Colors.green : Colors.amber,
                                    size: 30,
                                  ),
                                  iconAlignment: IconAlignment.values[0],
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.all(5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Render QR preview if name is valid
                        if (_eventName != null && _eventName!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 200,
                              width: 200,
                              child: PrettyQrView.data(
                                data: _eventName!, // data contained in the qr code
                                decoration: const PrettyQrDecoration(
                                  shape: PrettyQrSquaresSymbol(),
                                  background: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Create Event Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreatingEvent ? null : _createEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isCreatingEvent
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Creating Event...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Create Event',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
