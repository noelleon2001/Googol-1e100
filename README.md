
# Bin Brain: Googol 1e100

BinBrain is an innovative app that uses advanced object detection with a waste classification model to make recycling easier and more accessible for everyone. Developed using Google technologies such as Flutter, MLKit, Firebase and Google Cloud Storage as well as TensorFlow, Binbrain is a solution targeting to achieve three of the Sustainable Development Goals (SDGs), which are Sustainable Cities and Communities, Responsible Consumption, Life below Water and Life on Land. 

## Getting Started
### Initial Setup
1. [Install Flutter](https://docs.flutter.dev/get-started/install) on your OS and set up your [Android device/emulator](https://docs.flutter.dev/get-started/install/windows#android-setup). 
*Note: BinBrain was only tested on an Android device/emulator.*
2. Clone the repository by running `git clone https://github.com/noelleon2001/Googol-1e100.git`  
3. BinBrain uses the [Google Maps API](https://developers.google.com/maps). To use our app, you need to generate an API key by following the instructions [here](https://developers.google.com/maps/get-started). Add your API key to a `.env` file in the root directory of the repository as `GMAP_KEY`. 

You will also need to add the the API key to the AndroidManifest.xml file under `/android/app/src/main/AndroidManifest.xml`

```
<application>
  ...
  <meta-data android:name="com.google.android.geo.API_KEY"
           android:value=<GMAP_KEY>/>
</application>
```


### Running BinBrain
1. Ensure your Android device is connected or AVD is recognised by running `flutter devices`. You can run your AVD through [Android Studio's Device Manager](https://developer.android.com/studio/run/managing-avds) or through the [CLI](https://developer.android.com/studio/run/emulator-commandline).
2. Use the command `flutter run`


## Navigating the App
BinBrain consists of four different tabs, Home, Object Detector, Map and Contribute.

- **Home**: View your stats on total classified and verified objects, waste disposal facts and information about the other tabs.
- **Object Detector**:  The Object detector view supports live object detection and classification as well as taking a photo live to classify or a picture from your gallery to identify organic or recyclable wastes. The user can switch between two models that classify an image to 
  1. Types of waste: Paper, Plastic, Trash, Metal (This model is to be improved with more label options in the future)
  2. Recyclable and Organic
- **Map**: Find the closest Recycling Centers and Waste Collection for recycling. Also, view a Heatmap visualising the locations of recently classified wastes.
- **Contribute**: Classify waste images and verify other images to ensure that they are classified properly. These images will be used in our training dataset to further improve our classification model. 

