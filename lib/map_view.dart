import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;

  LatLng? currentLatLng;
  Location location = Location();
  LocationData? _currentLocation;


  @override
  void initState() {
    super.initState();
    getLocation();
    findPlaces();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return currentLatLng == null ? Center(child: CircularProgressIndicator(),) : GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: currentLatLng!,
        zoom: 11.0,
      ),
      myLocationEnabled: true,
    );
  }


  getLocation() async{
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();

    if (_currentLocation != null){
      currentLatLng = LatLng(_currentLocation!.latitude!,_currentLocation!.longitude!);
      location.onLocationChanged.listen((LocationData currentLocation) {
        if (mounted){
          setState(() {
            _currentLocation = currentLocation;
            currentLatLng = LatLng(currentLocation.latitude!,currentLocation.longitude!);

          });
        };
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void findPlaces() async{
    var url = Uri.https('maps.googleapis.com', 'maps/api/place/findplacefromtext/json', {'input': 'Recycle', 'inputtype':'textquery', 'key': 'API_KEY'});
    var response = await http.post(url);
    print('Response.body: ${response.body}');
  }
}
