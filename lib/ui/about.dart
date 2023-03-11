import 'package:flutter/material.dart';
import "package:flutter_about_page/flutter_about_page.dart";


class AboutView extends StatelessWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AboutPage ab = AboutPage();
    ab.customStyle(descFontFamily: "Roboto",listTextFontFamily: "RobotoMedium");

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("About Page"),
          centerTitle: true,
        ),
        body: ListView(

          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ab.setImage("assets/logo.png"),
            ),
            Center(
              child: ab.addDescription("Can ChatGPT classify trash tho?"),
            ),
            ab.addWidget(
              const Text(
                "Version 1.0",
                style: TextStyle(
                    fontFamily: "RobotoMedium"
                ),
              ),
            ),
            const SizedBox(height: 8),
            ab.addDescription('BinBrain is an innovative app that uses Advanced Object Detection to make recycling easier and more accessible for everyone'),
            ab.addDescription('Designed by Chung Chin Leon and Sadeeptha Bandara for Kitahack 2023'),
            ab.addGroup("Connect with us"),
            ab.addEmail("hban0006@student.monash@gmail.com"),

          ],
        )
    );
  }
}