import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import 'package:google_fonts/google_fonts.dart';

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
          primary: const Color(0xFF58D5D3),
          secondary: const Color(0xFF58D5D3)
        ), 
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
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
  bool _switch = false;

  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return _switch ? const Scaffold(body: Center(child: CircularProgressIndicator())) : PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: const Color(0xFF58D5D3),// Default is Colors.white.
      resizeToAvoidBottomInset: true,
      hideNavigationBarWhenKeyboardShows:
      true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style14,
      onItemSelected: _onItemTapped,

      // Choose the nav bar style with this property.
    );
  }

  void _onItemTapped(int index) async {
    setState(() {
      _switch = true;
    });
    // await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _switch = false;
    });
  }

  List<Widget> _buildScreens() {
      return [
        const ObjectDetectorView(),
        const MapView(),
        const GameView(),
        const AboutView()
      ];
    }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey5,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.map),
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey5,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.photo_library_sharp),
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey5,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.info),
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey5,
      ),
    ];
  }


}