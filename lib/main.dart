import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';


import 'ui/map_view.dart';
import 'ui/object_detector_view.dart';
import 'ui/settings.dart';
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
  final response = await FirebaseObjectDetectorModelManager().downloadModel(modelName);
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
        primarySwatch: Colors.blue,
      ),
      home:  const NavigationBarWidget(),
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
  int _selectedIndex = 0;
  bool _switch = false;

  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  static const List<Widget> _widgetOptions = <Widget>[
    ObjectDetectorView(),
    MapView(),
    GameView(),
    SettingsView()
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
      _switch = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _switch = false;
    });
  }

  List<Widget> _buildScreens() {
    return [
      const ObjectDetectorView(),
      const MapView(),
      const GameView(),
      const SettingsView()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("Home"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary:Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.map),
        title: ("Map"),
        activeColorPrimary: Colors.green,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.photo_library_sharp),
        title: ("Photo"),
        activeColorPrimary: Colors.orangeAccent,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: ("Settings"),
        activeColorPrimary: Colors.grey,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: ItemAnimationProperties( // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: ScreenTransitionAnimation( // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style1,
      // Choose the nav bar style with this property.
    );


    // return Scaffold(
    //   body: Center(
    //     child: _switch == true ? const CircularProgressIndicator() : _widgetOptions.elementAt(_selectedIndex),
    //   ),
    //   bottomNavigationBar: BottomNavigationBar(
    //     items: const <BottomNavigationBarItem>[
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.home),
    //         label: 'Home',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.map),
    //         label: 'Map',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.add_a_photo),
    //         label: 'Game',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.settings),
    //         label: 'Settings',
    //       ),
    //     ],
    //     currentIndex: _selectedIndex,
    //     selectedItemColor: Colors.blue[800],
    //     unselectedItemColor: Colors.grey[800],
    //     onTap: _onItemTapped,
    //   ),
    // );
  }
}

