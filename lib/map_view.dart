import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as gs;
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:map_launcher/map_launcher.dart' as mpl;
import 'dart:developer' as dev;

import './models.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();


class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;

  LatLng? currentLatLng;
  Location location = Location();
  LocationData? _currentLocation;
  final Mode _mode = Mode.overlay;

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
    return currentLatLng == null ? Center(child: CircularProgressIndicator(),) :
    Scaffold(
      appBar: AppBar(
        title: Text('Map'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _mapOpen,
              child: Icon(Icons.map_outlined),
            ),
          ),
        ]
      ),
      key: homeScaffoldKey,
      body: SafeArea(
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: currentLatLng!,
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          markers:markers,
          compassEnabled: false,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handlePressButton,
        child: const Icon(Icons.search)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  /*Called on init state*/
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

  void _mapOpen() async{
    var mapAvailable = await mpl.MapLauncher.isMapAvailable(mpl.MapType.google);

    if (mapAvailable != null && mapAvailable == true) {
      await mpl.MapLauncher.showMarker(
        mapType: mpl.MapType.google,
        coords: mpl.Coords(currentLatLng!.latitude, currentLatLng!.longitude),
        title: 'Current Location'
      );
    }
  }

  /*
  Sets markers
  * */
  void findPlaces() async{
    var url = Uri.https('maps.googleapis.com', 'maps/api/place/textsearch/json',
        {'query': 'waste',
          'radius': '5000',
          'location':'3.0639,101.600',
          'key': dotenv.env['GMAP_KEY']});
    var response = await http.post(url);

    Set<Marker> markers = <Marker>{};

    if (response.statusCode == 200){
      MapResponse mapResponse = MapResponse.fromJSON(jsonDecode(response.body));
      dev.log('MapResponse: ${mapResponse.status}');

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

  Future<void> _handlePressButton() async {


      gs.Prediction? p = await PlacesAutocomplete.show(
          context: context,
          apiKey: dotenv.env['GMAP_KEY']!,
          onError: onError,
          mode: _mode,
          language: 'en',
          strictbounds: false,
          types: [""],
          decoration: InputDecoration(
              hintText: 'Search',
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0),
                  borderSide: BorderSide(width: 3, style: BorderStyle.none))
          ),
          components: [gs.Component(gs.Component.country,"my")]);


        if (p != null){
          displayPrediction(p,homeScaffoldKey.currentState);
        }

  }

  void onError(gs.PlacesAutocompleteResponse response){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Message',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  Future<void> displayPrediction(gs.Prediction p, ScaffoldState? currentState) async {
    gs.GoogleMapsPlaces places = gs.GoogleMapsPlaces(
        apiKey: dotenv.env['GMAP_KEY'],
        apiHeaders: await const GoogleApiHeaders().getHeaders()
    );

    gs.PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    markers.clear();
    markers.add(Marker(markerId: const MarkerId("0"),position: LatLng(lat, lng),infoWindow: InfoWindow(title: detail.result.name)));

    setState(() {});

    mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }
}

