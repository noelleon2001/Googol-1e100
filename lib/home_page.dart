import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

/* Object detection code goes here */
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Text('This is the home page');
  }
}
