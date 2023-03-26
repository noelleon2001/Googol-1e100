import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:flutter/material.dart';
import '../interactive/take_pic.dart';
import '../interactive/verify.dart';

class selectView extends StatefulWidget {
  const selectView({Key? key}): super(key: key);

  @override
  selectViewState createState() => selectViewState();
}

class selectViewState extends State<selectView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Captures images'),
              onPressed: ()
              // async {
              //   await Navigator.of(context).push(
              //     MaterialPageRoute(
              //       builder: (context) => GameView(),
              //     ),
              //   );
              // }
                => PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: GameView(),
                withNavBar: false,
              ),
            ),
            ElevatedButton(
              child: const Text('Verify images'),
              onPressed: () => PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: VerifyView(),
                withNavBar: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

