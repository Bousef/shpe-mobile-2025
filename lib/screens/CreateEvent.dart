import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AppBar(
                      leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
                      ),
                      title: SHPEHeaderText(text: 'CREATE EVENT'),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 25),
                    InputField(text: 'Name', controller: eventNameController),
                    const SizedBox(height: 25),
                    InputField(text: 'Description', controller: eventDescriptionController),
                    const SizedBox(height: 25),
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
                          eventDateController.text = "${pickedDate.year.toString()}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF1F3F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        hintText: "Event Date (YYYY-MM-DD)",
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 25),
                    InputField(text: 'Time (00:00)', controller: eventTimeController),
                    const SizedBox(height: 25),
                    DropdownButtonFormField<String>(
                      value: _dropdownValue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      items: ['GBM', 'Tech', 'Pro-Dev', 'MentorSHPE', 'Projects', 'SHPEtinas', 'Outreach']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _dropdownValue = value),
                    ),
                    const SizedBox(height: 25),
                    InputField(text: 'Points', controller: eventPointsController),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: selectImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Flyer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_flyer != null)
                          const Icon(Icons.check, color: Colors.green, size: 30),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_flyer != null)
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Image.memory(_flyer!, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final eventName = eventNameController.text;
                            if (eventName.isNotEmpty) {
                              updateQR(eventName);
                            }
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Generate QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (qrImageBytes != null) {
                              final status = await Permission.storage.request();
                              if (status.isGranted) {
                                final temp = await getTemporaryDirectory();
                                final file = File('${temp.path}/qr_code.png');
                                await file.writeAsBytes(qrImageBytes!);
                                final result = await GallerySaver.saveImage(file.path);
                                if (result == true) {
                                  setState(() => _isSuccess = true);
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                          child: Icon(
                            _isSuccess ? Icons.check : Icons.download,
                            color: _isSuccess ? Colors.green : Colors.amber,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (qrImageBytes != null)
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Image.memory(qrImageBytes!, fit: BoxFit.contain),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
