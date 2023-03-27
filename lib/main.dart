import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import 'package:google_fonts/google_fonts.dart';

import 'ui/home.dart';
import 'ui/map_view.dart';
import 'ui/object_detector_view.dart';
import 'ui/about.dart';
import 'ui/game_view.dart';

List<CameraDescription> cameras = [];

/* Entry point to the app */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  cameras = await availableCameras();
  await dotenv.load(fileName: ".env");

  const modelName = 'adam_metadata';
  final response =
      await FirebaseObjectDetectorModelManager().downloadModel(modelName);
  print("Downloaded: $response");
  runApp(const MyApp());
}

/*High level App widget*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BinBrain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color.fromRGBO(12, 153, 104, 1),
          secondary: Color.fromRGBO(154, 169, 166, 1),
        ), 
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      home: const NavigationBarWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavigationBarWidget extends StatefulWidget {
  const NavigationBarWidget({Key? key}) : super(key: key);

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget> {
  int selectedIndex = 0;
  bool _switch = false;

  late PersistentTabController _controller;

  void _changePage (int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _onItemTapped(int index) async {
    setState(() {
      selectedIndex = index;
      _switch = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _switch = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      HomeView(buttonHandler: _changePage),
      ObjectDetectorView(),
      MapView(),
      SelectView(),
      AboutView()
    ];

    return Scaffold(
      body: Center(
        child: _switch == true ? CircularProgressIndicator() : _widgetOptions.elementAt(selectedIndex),
        ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: Color.fromARGB(23, 0, 0, 0),
                  blurRadius: 50.0,
              )
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(selectedIndex == 0 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(selectedIndex == 1 ? Icons.camera : Icons.camera_outlined),
                label: 'Classify',
              ),
              BottomNavigationBarItem(
                icon: Icon(selectedIndex == 2 ? Icons.map : Icons.map_outlined),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(selectedIndex == 3 ? Icons.add_a_photo : Icons.add_a_photo_outlined),
                label: 'Game',
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(selectedIndex == 4 ? Icons.info : Icons.info_outline),
              //   label: 'About',
              // ),
            ],
            currentIndex: selectedIndex,
            unselectedItemColor: Colors.grey[500],
            selectedFontSize: 0,
            unselectedFontSize: 0,
            onTap: _onItemTapped,
          ),
        )
      )
    );
  }
}