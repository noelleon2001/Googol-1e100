import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Set<Marker> markers = {};


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
      zoomGesturesEnabled: true,
      markers:markers,
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


  /*
  * api request -> json parse -> iterate -> place markers (use futurebuilder)
  * */
  void findPlaces() async{
    var url = Uri.https('maps.googleapis.com', 'maps/api/place/findplacefromtext/json',
        {'input': 'recycle',
        'inputtype':'textquery',
          'key': dotenv.env['GMAP_KEY'],
          'fields': 'formatted_address,geometry,name'});
    var response = await http.post(url);

    Set<Marker> markers = <Marker>{};

    if (response.statusCode == 200){
      MapResponse mapResponse = MapResponse.fromJSON(jsonDecode(response.body));
      print('MapResponse: ${mapResponse.status}');

      mapResponse.places.forEach((place) => {
        markers.add(Marker(
            markerId: MarkerId(place.name),
            position: place.latLng,
            infoWindow: InfoWindow(
                title: place.name,
                snippet: place.formattedAddress
            )))
      });

    }
    setState(() => {
      this.markers = markers
    });
  }
}

class MapResponse{
  final List<Place> places;
  final String status;

  const MapResponse({
    required this.places,
    required this.status
  });

  factory MapResponse.fromJSON(Map<String, dynamic> json){

    // candidates format: [{'formatted_address': '', ...}]
    final placesData = json['candidates'] as List<dynamic>;

    final places = placesData
        .map((place) => Place.fromJson(place))
        .toList();

    return MapResponse(
        places: places,
        status: json['status'] as String
    );
  }
}


class Place{
  final String formattedAddress;
  final String name;
  // final String location;
  final LatLng latLng;

  const Place({
    required this.formattedAddress,
    required this.name,
    required this.latLng
  });

  factory Place.fromJson(Map<String, dynamic> json){
    print(json);
     var location = json['geometry']['location'] as Map<String, dynamic>,
         lat = location['lat'],
         lng = location['lng'];

    return Place(
      formattedAddress: json['formatted_address'],
      latLng: LatLng(lat!, lng!),
      name: json['name']
    );
  }
}