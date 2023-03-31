
# Bin Brain: Googol 1e100

BinBrain is an app that leverages artificial intelligence using an advanced classification model to make recycling easier and more accessible for everyone. Developed using Google technologies such as Flutter, Firebase and Google Cloud Storage, Binbrain is a solution targeting to achieve three of the Sustainable Development Goals (SDGs), which are Sustainable Cities and Communities, Responsible Consumption and Production and Life on Land. 

## Getting Started
### Initial Setup
1. [Install Flutter](https://docs.flutter.dev/get-started/install) on your OS and set up your [Android device/emulator](https://docs.flutter.dev/get-started/install/windows#android-setup). 
*Note: BinBrain was only tested on an Android device/emulator*
2. Clone the repository by running `git clone https://github.com/noelleon2001/Googol-1e100.git`  
3. BinBrain uses the [Google Maps API](https://developers.google.com/maps). To use our app, you need to generate an API key by following the instructions [here](https://developers.google.com/maps/get-started). Add your API key to a `.env` file in the root directory of the repository as `GMAP_KEY`

### Running BinBrain
1. Ensure your Android device is connected or AVD is recognised by running `flutter devices`. You can run your AVD through [Android Studio's Device Manager](https://developer.android.com/studio/run/managing-avds) or through the [CLI](https://developer.android.com/studio/run/emulator-commandline).
2. Use the command `flutter run`


## About the App
BinBrain consists of four different tabs, Home, Object Detector, Map and Contribute.

- **Home**: View your stats on total classified and verified objects, waste disposal facts and infomation about the other tabs.
- **Object Detector**: Utilizing an classification model, use your camera or a picture from your gallery to identify organic or recyclable wastes.
- **Map**: Find the closest Recycling Centers and Waste Collection for recycling. Also, view a Heatmap visualising the locations of recently classified wastes.
- **Contribute**: Classify waste images and verify other images to ensure that they are classified properly. These images will be used in our training dataset to further improve our classification model. 

