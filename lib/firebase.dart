import 'dart:io';

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import "dart:async";




class ModelDownloader{

   static String DEFAULT_MODEL_FILE_NAME = "detect.tflite";
   static const String DEFAULT_LABEL_FILE_NAME = "labelmap.txt";

   static Interpreter interpreter;

   static Future<FirebaseCustomModel> download() async {

    try {
      final FirebaseCustomModel model = await FirebaseModelDownloader.instance
          .getModel(
          "waste-detector",
          FirebaseModelDownloadType.localModelUpdateInBackground,
          FirebaseModelDownloadConditions(
            iosAllowsCellularAccess: true,
            iosAllowsBackgroundDownloading: false,
            androidChargingRequired: false,
            androidWifiRequired: false,
            androidDeviceIdleRequired: false,
          ));

      final localModelPath = model.file;
      print("Path in source : $localModelPath");
      interpreter = loadModelFromFile(localModelPath);

    } on Exception catch (e) {

      print("Firebase model load error");
      interpreter = await loadModelFromAsset();
    }
  }

   static Future<Interpreter> loadModelFromAsset() {
     return Interpreter.fromAsset(
         DEFAULT_MODEL_FILE_NAME,
         options: InterpreterOptions()..threads = 4);
   }

   static Interpreter loadModelFromFile(File file){
     return Interpreter.fromFile(
         file,
         options: InterpreterOptions()..threads = 4
     );
   }

   //Private constructor: class is uninstantiable
   ModelDownloader._();
}


