import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Container(
            child: SvgPicture.asset(
          'assets/header.svg',
          width: 600,
          fit: BoxFit.cover,
        )),
        Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Column(children: [
              SizedBox(height: 80),
              Stack(
                children: [
                  Text(
                    'Hi, Leon!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = Color.fromRGBO(12, 153, 104, 1),
                    ),
                  ),
                  Text(
                    'Hi, Leon!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0),
                ),
                color: Colors.lightBlueAccent.withOpacity(0.5),
                child: Text('testing'),
              ),
              Text('testing'),
              Text('testing'),
              Text('testing'),
            ]))
      ],
    ));
  }
}
