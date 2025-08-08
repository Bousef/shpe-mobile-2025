import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shpeucfmobile/screens/login.dart';
import 'package:shpeucfmobile/widgets/custom_button.dart';
import 'package:shpeucfmobile/screens/homescreen.dart';
import 'package:shpeucfmobile/widgets/custom_inputFields.dart';
import 'package:shpeucfmobile/services/firebase_auth_service.dart';
import 'package:shpeucfmobile/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class CreateEvent extends StatefulWidget{

    const CreateEvent({super.key});

    @override
    State <CreateEvent> createState() => _CreateEventState();


}



 //add feature that lets admin upload flyer image
class _CreateEventState extends State<CreateEvent>{
  int _selectedIndex = 2; // Start on Create Event page

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDescriptionController = TextEditingController();
  final TextEditingController eventDateController = TextEditingController();
  final TextEditingController eventTimeController = TextEditingController();
  final TextEditingController eventPointsController = TextEditingController();
  

  Uint8List? _flyer;

  //function that allows user to pick an image
  pickImage(ImageSource source) async{
    //function to make user pick image from gallery (flyer image)
    final ImagePicker _imagePicker = ImagePicker();

    XFile? _file = await _imagePicker.pickImage(source: source);

    if (_file != null){
      return await _file.readAsBytes();

    }

     else {
       print('No image selected');
       
     }
  }

  

  //add function to upload flyer image
   Future selectImage() async{
    //function to make user pick image from gallery (flyer image)
    Uint8List? img = await pickImage(ImageSource.gallery);

   
    setState(() {
      _flyer = img;
    });

  }

  
  //this section takes care of the qr code generator
  @protected
  late QrCode qrCode;

  late QrImage qrImage = QrImage(
    QrCode.fromData(
      data: 'sample', 
      errorCorrectLevel:QrErrorCorrectLevel.H));
  
  late PrettyQrDecoration qrDecoration;
  Uint8List? _qrImageBytes;
  
  Widget? qrWidget;
  Uint8List? qrImageBytes;
  String? _eventName = '';

  @override
  void initState(){
    super.initState();
    initQR();
  
  }

  Future<void> initQR() async{
    final name = eventNameController.text;
    qrCode = QrCode.fromData(
      data: name, 
      errorCorrectLevel: QrErrorCorrectLevel.H);

      final qrImage = QrImage(qrCode);
      
      qrDecoration = const PrettyQrDecoration(
        background: Colors.white,
        
      );

  }

  Future<void> updateQR(String newName) async {

    _eventName = newName;
    final qrCode = QrCode.fromData(
      data:_eventName!,
      errorCorrectLevel: QrErrorCorrectLevel.H);

    final qrImage = QrImage(qrCode);
    final qrBytes = await qrImage.toImageAsBytes(
      size: 512,
      format: ImageByteFormat.png,
      decoration: const PrettyQrDecoration(
        background: Colors.white,
        shape: PrettyQrSquaresSymbol(),
      ),
    );

    setState(() {
      qrImageBytes = qrBytes?.buffer.asUint8List();
    });

  }



  bool _isSuccess = false;
  

  //Section for the drop down menu
  String? _dropdownValue = 'GBM';




  @override
  Widget build(BuildContext context){
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;


    return Scaffold(

      body: Stack(
        fit: StackFit.expand,
        children:[
          Positioned.fill(
            child: Image.asset('lib/images/background.png', fit: BoxFit.cover),
          ),

           SafeArea(
            child: Stack(
              children:[
               Padding(
                  padding: EdgeInsets.only(bottom:50),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Column(
                      //creates input fields for the event
                      children: [ //the arrow wont move more to the left, title is a bit skewed
                        AppBar(
                          leading: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              }, 
                              icon: Icon(Icons.arrow_back_ios, color: Colors.amber, size:20),
                          )),
                          title: SHPEHeaderText(text: 'CREATE EVENT'), 
                          titleSpacing: 0,
                          centerTitle: true,
                          backgroundColor: Colors.transparent), 
                        //add a function for the header (put it inside another class)
                        SizedBox(height: 25),
                        InputField(text: 'Name', controller: eventNameController),
                        SizedBox(height: 25),
                        InputField(text: 'Description', controller: eventDescriptionController),
                        SizedBox(height: 25),
                        //InputField(text: 'Date', controller: eventDateController),
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
                              String formatted = "${pickedDate.year.toString()}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              eventDateController.text = formatted;
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F3F7),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.all(Radius.circular(30.0))),
                            hintText: "Event Date (YYYY-MM-DD)", 
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              
                            ),
                            suffixIcon: Icon(Icons.calendar_today)
                          ),
                        ),
                        SizedBox(height: 25),
                        InputField(text: 'Time (00:00)', controller: eventTimeController),
                        SizedBox(height: 25),
                        
                        
                        //drop down menu for event type
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                            
                          ),

                          height: 60,
                          
                          child: DropdownMenu(

                              onSelected: (value){
                                if (value != null){
                                  setState(() {
                                    _dropdownValue = value;
                  
                                  });

                                }

                              },
                              label: const Text('Event Type'),
                              textAlign:TextAlign.start,
                              trailingIcon: Icon(Icons.arrow_drop_down),
                              width: 415,
                              initialSelection : _dropdownValue,
                              enableFilter: true,
                              enableSearch: true,
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStatePropertyAll(Colors.white),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Colors.transparent, width: 1.5),
                                  ),
                                  
                                ),
                              ),


                              dropdownMenuEntries: <DropdownMenuEntry<String>>[
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
                                border: InputBorder.none, //removes the default border
                              ),
                              
                            ),
                        ),
                            
                        
                        
                        SizedBox(height: 25),
                        InputField(text: 'Points', controller: eventPointsController),
                        SizedBox(height: 30),
                        
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
                                )
                              ),
                              label: const Text('Upload Flyer', style: TextStyle(color: Colors.white, fontSize:20)),
                              icon: const Icon(Icons.upload_file, color: Colors.white, size: 20),
                              
                              ),
                            ),

                              SizedBox(width:10),

                              //this widget adds a checkmark icon if flyer is uploaded
                              Align(
                                alignment: Alignment.centerLeft,
                                child:
                                _flyer != null ? 
                                    Icon(Icons.check, color: Colors.green, size: 30) : SizedBox(height:0),

                              ) 
                              
                            ],
                           
                           
                           ),

                        SizedBox(height: 20),

                        _flyer != null ?
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 200,
                              width: 200, 
                              child: Image.memory(_flyer!, fit: BoxFit.cover),
                                  
                            ),
                          )

                          : const SizedBox(height:0),
                                
                
    
                        SizedBox(height: 20),
                             
                          //QR CODE GENERATOR SECTION//
                         Row(
                             
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton.icon(
                                onPressed: () {
                                    final eventName = eventNameController.text;
                                    if(eventName.isNotEmpty){
                                      updateQR(eventName); //generates the qr code and image is stored as bytes
                                    }
                                      
                                },
                                icon: const Icon(Icons.qr_code, 
                                  color: Colors.white, size: 20),
                                label: const Text('Generate QR Code', style: TextStyle(color: Colors.white, fontSize: 20)),
                                style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                )
                                  
                               ),
                                
                              ),

                                SizedBox(width: 10),
                              

                                Align(
                                  alignment: Alignment.centerRight,

                                  child: SizedBox(
                                    height: 48,
                                    width: 48, 
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        if (qrImageBytes != null){
                                          //requests permission to save to gallery
                                          final status = await Permission.storage.request();

                                          if(status.isDenied){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Permission denied.')),
                                            );
                                          }

                                          //since the qr code is stored in bytes, the  bytes are written to the file
                                          final temp = await getTemporaryDirectory();
                                          final file = File('${temp.path}/qr_code.png');
                                          await file.writeAsBytes(qrImageBytes!);

                                          final result = await GallerySaver.saveImage(file.path);

                                          if(result == true){ //if download is successful, boolean variable is set to true (helpful for icon change)
                                            setState(() {
                                               _isSuccess = true;
                                            });
                                          }


                                        }
                                      },
                                      label: const Text('Download', style: TextStyle(color: Colors.transparent)),
                                      
                                      icon:  Icon(_isSuccess ? Icons.check : Icons.download,
                                        color: _isSuccess ? Colors.green : Colors.amber,
                                        size: 30),
                                      iconAlignment: IconAlignment.values[0],

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,

                                        padding: const EdgeInsets.all(5),
                                        shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                      ),
          
                                      
                                    ),

                                  ),
                                ),
                            
                              ]



                           ),

                           SizedBox(height:20),

                           //This condition generates the view of the new qr code as long as event Name is valid
    
                           if (_eventName != null && _eventName!.isNotEmpty)

                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 200,
                                width: 200,
                                
                                child: PrettyQrView.data(
                                      
                                  data: _eventName!, //data contained in the qr code
                                  decoration: const PrettyQrDecoration(
                                        //stylistic options
                                    shape: PrettyQrSquaresSymbol(),
                                    background: Colors.white,
                                        //ask if image in the middle is desired

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
     ]),
    );
  }



}
