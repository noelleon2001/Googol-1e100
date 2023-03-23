import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:gcloud/storage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mime/mime.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../main.dart';

Future loadAsset() async {
  return await rootBundle.loadString('assets/credentials.json');
}

// A screen that allows users to take a picture using a given camera.
class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  GameViewState createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final camera = cameras.first;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    _controller.setFlashMode(FlashMode.off);
  }

  @override
  void dispose(){
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picture Classification')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Center(child: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            if (!mounted) return;

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);
  final String imagePath;

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}


// A widget that displays the picture taken by the user.
class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  // DisplayPictureScreen({super.key, required this.imagePath});
  bool loading = false;

  Widget upload_dialog(BuildContext context, String _option) {
    return AlertDialog(
      title: const Text('Upload image to...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$_option'),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.red, // Background color
            onPrimary: Colors.black, // Text Color (Foreground color)
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            upload(_option);
          },
          child: const Text('Confirm'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  void _success() async{
    if (loading) {
      Center(
        child: CircularProgressIndicator(),
      );
    }
    // pop up
    await showDialog(
      context: context,
      builder: (BuildContext context) => _buildPopupDialog(context, true),
    );

    Navigator.of(context).pop();
  }

  void _failure() async{
    if (loading) {
      Center(
        child: CircularProgressIndicator(),
      );
    }
    // pop up
    await showDialog(
      context: context,
      builder: (BuildContext context) => _buildPopupDialog(context, false),
    );

    // pop display image screen
    Navigator.of(context).pop();
  }

  void upload(fileLocation) async{
    setState(() {
      loading = true;
    });

    // Set up Google Cloud Storage
    try {
      final _json = await loadAsset();
      final credentials = await auth.ServiceAccountCredentials.fromJson(_json);
      final client = await auth.clientViaServiceAccount(credentials, Storage.SCOPES);
      final storage = Storage(client, 'googol-1e100');

      // Generate random file name
      final fileName = 'dataset/$fileLocation/${DateTime.now().millisecondsSinceEpoch}-${path.basename(widget.imagePath)}';

      // Open image file and upload to GCS
      final imageFile = File(widget.imagePath);
      final bucket = storage.bucket('googol-1e100.appspot.com');
      final imageBytes = imageFile.readAsBytesSync();
      final type = lookupMimeType(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await bucket.writeBytes(fileName, imageBytes,
          metadata: ObjectMetadata(
            contentType: type,
            custom: {
              'timestamp': '$timestamp',
            },
          ));

      setState(() {
        loading = false;
      });

      _success();
    } catch(e){
      setState(() {
        loading = false;
      });

      _failure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(child: Image.file(File(widget.imagePath))),
      floatingActionButton: SpeedDial( //Speed dial menu
        icon: Icons.menu, //icon on Floating action button
        activeIcon: Icons.close, //icon when menu is expanded on button
        backgroundColor: Colors.blue, //background color of button
        foregroundColor: Colors.white, //font color, icon color in button
        activeBackgroundColor: Colors.blue, //background color when menu is expanded
        activeForegroundColor: Colors.white,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'), // action when menu opens
        onClose: () => print('DIAL CLOSED'), //action when menu closes

        elevation: 8.0, //shadow elevation of button
        shape: CircleBorder(), //shape of button

        children: [
          SpeedDialChild(
            child: Icon(Icons.shopping_bag),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Plastic',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'plastic'),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.iron),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Metal',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'metal'),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.card_giftcard),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Cardboard',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'cardboard'),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.newspaper),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Paper',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'paper'),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.hourglass_bottom),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Glass',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'glass'),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.currency_bitcoin),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Trash',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'trash'),
              );
            },
          ),

        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   // Provide an onPressed callback.
      //   onPressed: () async {
      //     try {
      //       upload();
      //       if (loading) {
      //         Center(
      //           child: CircularProgressIndicator(),
      //         );
      //       }
      //       // pop up
      //       await showDialog(
      //         context: context,
      //         builder: (BuildContext context) => _buildPopupDialog(context),
      //       );
      //
      //       Navigator.of(context).pop();
      //     } catch (e) {
      //       // If an error occurs, log the error to the console.
      //       print(e);
      //     }
      //   },
      //   child: const Icon(Icons.check),
      // ),
    );
  }
}

Widget _buildPopupDialog(BuildContext context, bool _status) {
  return AlertDialog(
    title: const Text('Notification:'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _status ? Text("Upload Success", style: TextStyle(decoration: TextDecoration.none,color: Colors.black,),)
            : Text("Upload Fail!\n(Bad internet connection)", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red,),),
      ],
    ),
    actions: <Widget>[
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}

