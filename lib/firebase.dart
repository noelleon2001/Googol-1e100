import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import "dart:async";

import 'tflite/classifier.dart';


class ModelDownloader{
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
      Classifier.setModelMode(mode: ModelMode.asset);
      // Classifier.setModelMode(mode:ModelMode.network, modelPath: localModelPath);
    } on Exception catch (e) {
      print("Firebase model load error");
      Classifier.setModelMode(mode: ModelMode.asset);
    }
  }
}


