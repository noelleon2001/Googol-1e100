import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:flutter/material.dart';
import '../interactive/take_pic.dart';
import '../interactive/verify.dart';
import 'package:lottie/lottie.dart';

class SelectView extends StatefulWidget {
  const SelectView({Key? key}) : super(key: key);

  @override
  SelectViewState createState() => SelectViewState();
}

class SelectViewState extends State<SelectView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contribute")),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.network(
                "https://assets7.lottiefiles.com/packages/lf20_qaemdbel.json"),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 30, child: Icon(Icons.add_a_photo, size: 15)),
                      const Text('Capture images')
                    ]),
                onPressed: ()
                    // async {
                    //   await Navigator.of(context).push(
                    //     MaterialPageRoute(
                    //       builder: (context) => GameView(),
                    //     ),
                    //   );
                    // }
                    =>
                    PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: GameView(),
                  withNavBar: false,
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 30, child: Icon(Icons.check_box, size: 17)),
                      const Text('Verify images')
                    ]),
                onPressed: () => PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: VerifyView(),
                  withNavBar: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
