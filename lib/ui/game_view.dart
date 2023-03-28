import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:flutter/material.dart';
import '../interactive/take_pic.dart';
import '../interactive/verify.dart';

class SelectView extends StatefulWidget {
  const SelectView({Key? key}): super(key: key);

  @override
  SelectViewState createState() => SelectViewState();
}

class SelectViewState extends State<SelectView> {

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
              child: const Text('Capture images'),
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

