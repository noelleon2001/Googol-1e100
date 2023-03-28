import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flip_card/flip_card.dart';

import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  final Function(int) buttonHandler;

  const HomeView({Key? key, required this.buttonHandler}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int? year;
  String? data;
  String? key;

  int _uploaded = 0;
  int _verified = 0;

  @override
  void initState() {
    super.initState();
    getUserStats();
    fetchData();
  }

  void getUserStats() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('upload')){
      _uploaded = prefs.getInt('upload')!;
    }

    if (prefs.containsKey('verify')){
      _verified = prefs.getInt('verify')!;
    }
  }

  void fetchData() async {
    // get random year between 2010 and 2022
    int year_min = 2010;
    int year_max = 2022;
    Random rnd = new Random();
    if (this.mounted) {
      setState(() {
        year = year_min + rnd.nextInt(year_max - year_min);
      });
    }

    var url = Uri.parse(
        'https://data.splitgraph.com:443/internal-chattadata/solid-waste-and-recycling-website-data-79t8-mn8i/latest/-/rest/solid_waste_and_recycling_website_data?year=eq.${year}');
    var response = await http.get(url);

    var result = jsonDecode(response.body)[0];

    int index_min = 2;
    int index_max = 7;
    int index = index_min + rnd.nextInt(index_max - index_min);

    var key_values = result.keys.elementAt(index).split('_');

    if (this.mounted) {
      setState(() {
        key = '${key_values[0]} ${key_values[1]}';
        data = result.values.elementAt(index).toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _buttonTexts = [
      {
        "title": "Object Detector",
        "text": "Determine type of wastes using the camera",
        "page": 1,
        "icon": Icons.camera,
        "color": Color.fromRGBO(16, 200, 136, 1),
      },
      {
        "title": "Map",
        "text": "View important locations on the map",
        "page": 2,
        "icon": Icons.map,
        "color": Color.fromRGBO(16, 200, 136, 1),
      },
      {
        "title": "Classify Images",
        "text":
            "Classify and verify images to improve our model!",
        "page": 3,
        "icon": Icons.add_a_photo,
        "color": Color.fromRGBO(16, 200, 136, 1),
      },
    ];
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
            padding: EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 82),
              Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Text(
                            'Hi, Leon!',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Color.fromRGBO(12, 153, 104, 0.581),
                            ),
                          ),
                          const Text(
                            'Hi, Leon!',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        "Welcome back to BinBrain.",
                        style: TextStyle(
                            color: Color.fromARGB(154, 0, 0, 0), fontSize: 17),
                      ),
                    ],
                  )),
              SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        color: Colors.grey.shade100,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                right: 17.5,
                                top: 17.5,
                                left: 17.5,
                                bottom: 12.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("You've classified",
                                    style:
                                        TextStyle(color: Colors.grey.shade700)),
                                const SizedBox(height: 7.5),
                                Text('$_uploaded objects',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2.5),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.arrow_drop_up,
                                      color: Colors.green,
                                    ),
                                    Text("24% vs avg",
                                        style: TextStyle(color: Colors.green)),
                                  ],
                                )
                              ],
                            ))),
                  ),
                  const SizedBox(width: 7.5),
                  Expanded(
                    child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        color: Colors.grey.shade100,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                right: 17.5,
                                top: 17.5,
                                left: 17.5,
                                bottom: 12.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("You've verified",
                                    style:
                                        TextStyle(color: Colors.grey.shade700)),
                                const SizedBox(height: 7.5),
                                Text('$_verified images',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2.5),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.red,
                                    ),
                                    Text("12% vs avg",
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                )
                              ],
                            ))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  color: Colors.green.shade600.withOpacity(0.5),
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb, color: Colors.amber),
                              SizedBox(
                                width: 7.5,
                              ),
                              Text('Did you know?',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 7.5),
                          data != null
                              ? Text(
                                  'In ${year}, a total of ${data} tonnes of rubbish was collected from ${key}!',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: const Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.0)))),
                        ],
                      ))),
              const SizedBox(height: 10),
              Text('Our key features:', style: TextStyle(fontWeight: FontWeight.w400,fontSize: 16)),
              Expanded(
                  child: Row(
                children: [
                  for (var buttonText in _buttonTexts)
                    Expanded(
                        child: FlipCard(
                      fill: Fill
                          .fillBack, // Fill the back side of the card to make in the same size as the front.
                      direction: FlipDirection.HORIZONTAL, // default
                      side: CardSide.FRONT, // The side to initially display.
                      front: Container(
                        child: Card(
                          clipBehavior: Clip.hardEdge,
                          color: Colors.grey.shade100,
                          child: InkWell(
                            splashColor: Colors.blue.withAlpha(30),
                            // onTap: () {
                            //   widget.buttonHandler(
                            //       int.parse(buttonText['page'].toString()));
                            // },
                            child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        height: 60,
                                        child: Center(
                                          child: Icon(
                                              size: 35,
                                              buttonText['icon'] as IconData?,
                                              color: buttonText['color'] as Color?),
                                        )),
                                    Center(
                                        child: Text(
                                            buttonText['title'].toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 17.5))),
                                    // Text(buttonText['text'].toString()),
                                  ],
                                )),
                          ),
                        ),
                      ),
                      back: Container(
                        child: Card(
                          clipBehavior: Clip.hardEdge,
                          color: Colors.grey.shade100,
                          child: InkWell(
                            splashColor: Colors.blue.withAlpha(30),
                            child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                        child: Text(
                                            buttonText['text'].toString(),
                                            textAlign: TextAlign.center)),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.grey.shade700,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(50, 30),
                                        ),
                                        onPressed: () {
                                          widget.buttonHandler(int.parse(
                                              buttonText['page'].toString()));
                                        },
                                        child: Text('Go'))
                                  ],
                                )),
                          ),
                        ),
                      ),
                    )),
                ],
              ))
            ]))
      ],
    ));
  }
}
