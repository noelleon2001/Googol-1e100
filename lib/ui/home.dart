import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:convert';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int? year;
  String? data;
  String? key;

  @override
  void initState() {
    super.initState();
    fetchData();
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

    dev.log(key.toString());
    dev.log(data.toString());
  }

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
            padding: EdgeInsets.only(left: 15, right: 15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 85),
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
                                const Text('23 objects',
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2.5),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.arrow_drop_up,
                                      color: Colors.green,
                                    ),
                                    Text("24% than average",
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
                                const Text('5 images',
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2.5),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.red,
                                    ),
                                    Text("12% than average",
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
                              : const Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.0))),
                        ],
                      ))),
              const SizedBox(height: 10),
              Text(
                  'Help improve our object detection model by classifying waste and validating images!'),
            ]))
      ],
    ));
  }
}
