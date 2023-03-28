import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
// import 'package:googleapis_auth/auth_io.dart' as auth;
// import 'package:gcloud/storage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:mime/mime.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// Future loadAsset() async {
//   return await rootBundle.loadString('assets/credentials.json');
// }

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
  bool _loading = false;
  late Position location;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    Position location;

    setState(() {
      _loading = true;
    });
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    location = await Geolocator.getCurrentPosition();
    setState(() {
      _loading = false;
    });
    return location;
  }

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
    //Navigator.of(context).pop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Capture Image'),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () async{
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) => _helpDialog(context),
                  );
                },
                child: Icon(Icons.question_mark),
              ),
            ),
          ]
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Center(child: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return _loading ? const Center(child: CircularProgressIndicator()): CameraPreview(_controller);
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
            location = await _determinePosition();

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                  location: location,
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
  const DisplayPictureScreen({Key? key, required this.imagePath, required this.location}) : super(key: key);
  final String imagePath;
  final Position location;
  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}


// A widget that displays the picture taken by the user.
class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  // DisplayPictureScreen({super.key, required this.imagePath});
  bool loading = false;
  CollectionReference dataset = FirebaseFirestore.instance.collection('dataset');

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
    setState(() {
      loading = false;
    });
    // pop up
    await showDialog(
      context: context,
      builder: (BuildContext context) => _buildPopupDialog(context, true),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('upload')){
      await prefs.setInt('upload', 1);
    } else{
      await prefs.setInt('upload', prefs.getInt('upload')! + 1);
    }

    Navigator.of(context).pop();
  }

  void _failure() async{
    setState(() {
      loading = false;
    });
    // pop up
    await showDialog(
      context: context,
      builder: (BuildContext context) => _buildPopupDialog(context, false),
    );

    // pop display image screen
    Navigator.of(context).pop();
  }

  Future<void> addData(fileName, path, classification) async {

    print("----------------------------------------------------------------------------");
    print('${widget.location.latitude.toString()}, ${widget.location.longitude.toString()}');
    print("----------------------------------------------------------------------------");

    return dataset
        .doc(fileName)
        .set({
          'classification': classification,
          'filename': fileName,
          'collected_time': FieldValue.serverTimestamp(),
          'location': GeoPoint(widget.location.latitude.toDouble(), widget.location.longitude.toDouble()),
          'path': path,
          'verified': false,
        })
        .then((value) => print("Data Added"))
        .catchError((error) => print("Failed to add data: $error"));
  }

  void upload(fileLocation) async{
    setState(() {
      loading = true;
    });
    // Create the file metadata
    final metadata = SettableMetadata(contentType: "image/jpeg");

    // Generate random file name
    final imageName = '${DateTime.now().millisecondsSinceEpoch}-${path.basename(widget.imagePath)}';
    final imagePath = 'dataset/$fileLocation/$imageName';
    final imageFile = File(widget.imagePath);

    // Create a reference to the Firebase Storage bucket
    final storageRef = FirebaseStorage.instance.ref();
    try {
      // Upload file and metadata to the path 'images/mountains.jpg'
      final uploadTask = storageRef
          .child(imagePath)
          .putFile(imageFile, metadata);

      // Listen for state changes, errors, and completion of the upload.
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) async {
        switch (taskSnapshot.state) {
          case TaskState.running:
            final progress =
                100.0 *
                    (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            print("Upload is $progress% complete.");
            break;
          case TaskState.paused:
            print("Upload is paused.");
            break;
          case TaskState.canceled:
            print("Upload was canceled");
            break;
          case TaskState.error:
          // Handle unsuccessful uploads
            _failure();
            break;
          case TaskState.success:
          // Handle successful uploads on complete
          // ...
            _success();
            await addData(imageName, imagePath, fileLocation);
            break;
        }
      });
    } catch(e) {
      _failure();
    }


    // Set up Google Cloud Storage
    // try {
    //   final _json = await loadAsset();
    //   final credentials = await auth.ServiceAccountCredentials.fromJson(_json);
    //   final client = await auth.clientViaServiceAccount(credentials, Storage.SCOPES);
    //   final storage = Storage(client, 'googol-1e100');
    //   final name = '${DateTime.now().millisecondsSinceEpoch}-${path.basename(widget.imagePath)}';
    //   // Generate random file name
    //   final fileName = 'dataset/$fileLocation/$name';
    //
    //   // Open image file and upload to GCS
    //   final imageFile = File(widget.imagePath);
    //   final bucket = storage.bucket('googol-1e100.appspot.com');
    //   final imageBytes = imageFile.readAsBytesSync();
    //   final type = lookupMimeType(fileName);
    //   final timestamp = DateTime.now().millisecondsSinceEpoch;
    //
    //   await bucket.writeBytes(fileName, imageBytes,
    //       metadata: ObjectMetadata(
    //         contentType: type,
    //         custom: {
    //           'timestamp': '$timestamp',
    //         },
    //       ));
    //   await addData(name, fileName, fileLocation);
    //
    //   setState(() {
    //     loading = false;
    //   });
    //
    //   _success();
    // } catch(e){
    //   setState(() {
    //     loading = false;
    //   });
    //
    //   _failure();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Scaffold(body: Center(child: CircularProgressIndicator())):Scaffold(
      appBar: AppBar(title: const Text('Preview image')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(child: Image.file(File(widget.imagePath))),
      floatingActionButton: SpeedDial( //Speed dial menu
        icon: Icons.menu, //icon on Floating action button
        activeIcon: Icons.close, //icon when menu is expanded on button
        backgroundColor: Colors.greenAccent, //background color of button
        foregroundColor: Colors.white, //font color, icon color in button
        activeBackgroundColor: Colors.lightGreenAccent, //background color when menu is expanded
        activeForegroundColor: Colors.white,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'), // action when menu opens
        onClose: () => print('DIAL CLOSED'), //action when menu closes

        elevation: 8.0, //shadow elevation of button
        shape: const CircleBorder(), //shape of button

        children: [
          SpeedDialChild(
            child: const Icon(Icons.shopping_bag),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Plastic',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'plastic'),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.iron),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Metal',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'metal'),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.card_giftcard),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Cardboard',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) => upload_dialog(context, 'cardboard'),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.newspaper),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Paper',
            labelStyle: const TextStyle(fontSize: 18.0),
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

Widget _helpDialog(BuildContext context) {
  return AlertDialog(
    title: const Text('Tutorial:'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("This is a page where you can contribute by capturing an image, classify it, and it upload to our database.\n\nYour images will be used to train and fine-tune our model or help our developers that need it.\n\nFollow the 3 steps below to get started:\n\n1) Click the button with camera icon to capture an image with a trash.\n\n2) Click the menu button.\n\n3) Classify the trash with the options given, and confirm your choice.")
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