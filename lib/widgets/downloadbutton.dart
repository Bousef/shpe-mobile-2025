import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class Downloadbutton extends StatefulWidget {
  final String imageUrl;

  const Downloadbutton({super.key, required this.imageUrl});

  @override
  State<Downloadbutton> createState() => _DownloadbuttonState();
}

class _DownloadbuttonState extends State<Downloadbutton> {
  bool _isDownloading = false;
  bool _downloaded = false;

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Ask for permissions
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        // iOS and Android permissions
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied. Cannot save image.")),
        );
        return;
      }

      // Fetch image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download image.")),
        );
        return;
      }

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        quality: 100,
        name: "event_photo_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save image.")),
        );
      }
    } catch (e) {
      print("Download failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  void _Tap() async {
    if (_isDownloading || _downloaded) return;

    setState(() {
      _isDownloading = true;
    });

    await _downloadImage(widget.imageUrl);

    setState(() {
      _isDownloading = false;
      _downloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _Tap,
      iconSize: 30,
      icon: _isDownloading
          ? const SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              _downloaded ? Icons.cloud_done : Icons.cloud_download,
              color: _downloaded ? const Color(0xFFF2AC02) : Colors.white,
            ),
    );
  }
}
