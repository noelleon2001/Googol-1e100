import 'package:flutter/material.dart';
import "package:flutter_about_page/flutter_about_page.dart";


class AboutView extends StatelessWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AboutPage ab = AboutPage();
    ab.customStyle(descFontFamily: "Inter", listTextFontFamily: "InterMedium");

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("About BinBrain"),
        ),
        body: 
          ListView(
          children: [
            Padding (
              padding: const EdgeInsets.all(40),
              child: ab.setImage("assets/logo.png"),
            ),
            // Center(
            //   child: ab.addDescription("Can ChatGPT classify trash tho?"),
            // ),
            // ab.addWidget(
            //   const Text(
            //     "Version 1.0",
            //     style: TextStyle(
            //         fontFamily: "RobotoMedium"
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),
            Padding (
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ab.addDescription('BinBrain is an innovative app that leverages artificial intelligence using advanced object detection models to make recycling easier and more accessible for everyone.'),
            ),
            Padding (
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ab.addDescription('Designed and built by Chung Chin Leon and Sadeeptha Bandara for Kitahack 2023.'),
            ),
            Padding (
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ab.addGroup("Connect with us"),
            ),
            Padding (
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ab.addEmail("hban0006@student.monash@gmail.com"),
            ),
            
          ],
        )
    );
  }
}