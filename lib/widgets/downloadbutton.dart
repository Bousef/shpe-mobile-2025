import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class Downloadbutton extends StatefulWidget {
  const Downloadbutton({super.key});

  @override
  State<Downloadbutton> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Downloadbutton> {
  @override
  bool _isDownloading=false;
  bool _downloaded=false;
  

  void _Tap() async{
    if(_isDownloading || _downloaded) return;

    setState(() {
      _isDownloading=true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isDownloading=false;
      _downloaded=true;
    });
    
  }
  
  
  Widget build(BuildContext context) {
    return IconButton(
      onPressed:_Tap,
      iconSize:30,
      icon: _isDownloading? 
      const SizedBox(
        width:35, 
        height:35,
        child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
      :Icon(_downloaded ? Icons.cloud_done : Icons.cloud_download,
        color: _downloaded ? Color(0xFFF2AC02) : Colors.white,)
        
        
    );
    
  }
}