import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

enum DownloadStatus { idle, downloading, success, failure }

class Downloadbutton extends StatefulWidget {
  final String imageUrl;

  const Downloadbutton({super.key, required this.imageUrl});

  @override
  State<Downloadbutton> createState() => _DownloadbuttonState();
}

class _DownloadbuttonState extends State<Downloadbutton> {
  DownloadStatus _status = DownloadStatus.idle;
  // bool _isDownloading = false;
  // bool _downloaded = false;

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
        setState(() => _status = DownloadStatus.failure);
        return;
      }

      // Fetch image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download image.")),
        );
        setState(() => _status = DownloadStatus.failure);
        return;
      }

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        quality: 100,
        name: "event_photo_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   //const SnackBar(content: Text("Image saved.")),
        // );
        setState(() => _status = DownloadStatus.success);
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   //const SnackBar(content: Text("Failed to save image.")),
        // );
        setState(() => _status = DownloadStatus.failure);
      }
    } catch (e) {
      print("Download failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
      setState(() => _status = DownloadStatus.failure);
    }
  }

  void _Tap() async {
    if (_status == DownloadStatus.downloading || _status == DownloadStatus.success ) return;

    setState(() => _status = DownloadStatus.downloading);

    await _downloadImage(widget.imageUrl);

    setState(() => _status = DownloadStatus.success);
  }

  @override
  Widget build(BuildContext context) {
    Widget? icon;
    Text text;

    switch(_status){
      case DownloadStatus.downloading:
        icon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
        text = Text(
          'Download',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          )
        );
        break;
      case DownloadStatus.success:
        icon = const Icon(Icons.download_done, color: Colors.white);
        text = Text(
          'Downloaded!',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          )
        );
        break;
      case DownloadStatus.failure:
        icon = const Icon(Icons.close, color: Colors.redAccent);
        text = Text(
          'Download failed.',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          )
        );
        break;
      default:
        icon = const Icon(Icons.download, color: Colors.white);
        text = Text(
          'Download',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          )
        );
    }

    return ElevatedButton.icon(
      onPressed: _Tap,
      icon: icon,
      label: text,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        )
      ),
    );


    // --- OLD DOWNLOAD BUTTON ---
    // return IconButton(
    //   onPressed: _Tap,
    //   iconSize: 30,
    //   icon: _isDownloading
    //       ? const SizedBox(
    //           width: 35,
    //           height: 35,
    //           child: CircularProgressIndicator(
    //             strokeWidth: 3,
    //             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    //           ),
    //         )
    //       : Icon(
    //           _downloaded ? Icons.cloud_done : Icons.cloud_download,
    //           color: _downloaded ? const Color(0xFFF2AC02) : Colors.white,
    //         ),
    // );
  }
}
