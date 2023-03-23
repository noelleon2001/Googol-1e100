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

import '../models.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  static const List<String> markerOptions = ['Recycling Centres', 'Waste Collectors', 'Heatmap'];

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
  String dropDownValue = MapView.markerOptions.first;

  Set<Marker> markers = {};
  Set<Heatmap> heatmaps = {};

  @override
  void initState() {
    super.initState();
    getLocation();
    findPlaces(dropDownValue);
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
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: currentLatLng!,
                zoom: 14.0,
              ),
              heatmaps: heatmaps,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              markers:markers,
              compassEnabled: false,
            ),
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Container(
               padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(7)
               ),
               child: DropdownButton(
                   value: dropDownValue,
                   items: MapView.markerOptions.map<DropdownMenuItem<String>>((String value){
                     return DropdownMenuItem(value: value, child: Text(value));
                   }).toList(),
                   elevation: 16,
                   onChanged: (String? value){
                     setState(() {
                       dropDownValue = value!;
                     });
                     if (value != 'Heatmap') {
                      findPlaces(dropDownValue);
                      heatmaps.clear();
                     } else {
                      markers.clear();
                      fetchHeatmaps();
                     }
                   },
               ),
             ),
           )
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSearch,
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
  void findPlaces(String query) async{
    var url = Uri.https('maps.googleapis.com', 'maps/api/place/textsearch/json',
        {'query': query,
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
                snippet: place.formattedAddress,
            )))
      });

    }
    setState(() => {
      this.markers = markers
    });
  }

  Future<void> _handleSearch() async {
      gs.Prediction? p = await PlacesAutocomplete.show(
          context: context,
          apiKey: dotenv.env['GMAP_KEY']!,
          onError: onSearchError,
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
          markSearchLocation(p,homeScaffoldKey.currentState);
        }

  }

  void onSearchError(gs.PlacesAutocompleteResponse response){
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

  Future<void> markSearchLocation(gs.Prediction p, ScaffoldState? currentState) async {
    gs.GoogleMapsPlaces places = gs.GoogleMapsPlaces(
        apiKey: dotenv.env['GMAP_KEY'],
        apiHeaders: await const GoogleApiHeaders().getHeaders()
    );

    gs.PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    markers.clear();
    markers.add(Marker(
      markerId: MarkerId("0"),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: detail.result.name, 
        snippet: detail.result.formattedAddress,
      )));

    setState(() {});

    mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }

  void fetchHeatmaps() {
    final List<WeightedLatLng> points = [
      WeightedLatLng(LatLng(3.157525, 101.659132), weight: 2),
      WeightedLatLng(LatLng(3.097196, 101.707142), weight: 5),
      WeightedLatLng(LatLng(3.119851, 101.674244), weight: 7),
      WeightedLatLng(LatLng(3.157515, 101.689878), weight: 3),
      WeightedLatLng(LatLng(3.106070, 101.686937), weight: 6),
      WeightedLatLng(LatLng(3.156242, 101.668536), weight: 1),
      WeightedLatLng(LatLng(3.110774, 101.699199), weight: 8),
      WeightedLatLng(LatLng(3.089289, 101.711987), weight: 2),
      WeightedLatLng(LatLng(3.103030, 101.673949), weight: 9),
      WeightedLatLng(LatLng(3.143964, 101.683129), weight: 7),
      WeightedLatLng(LatLng(3.161042, 101.685302), weight: 4),
      WeightedLatLng(LatLng(3.103375, 101.670080), weight: 3),
      WeightedLatLng(LatLng(3.154829, 101.676574), weight: 2),
      WeightedLatLng(LatLng(3.128071, 101.700733), weight: 6),
      WeightedLatLng(LatLng(3.164278, 101.677390), weight: 8),
      WeightedLatLng(LatLng(3.120728, 101.703317), weight: 4),
    ];

    setState(() {
      heatmaps.add(
        Heatmap(
          heatmapId: HeatmapId('0'),
          data: points,
          radius: 30,
          opacity: 1,
          // gradient: HeatmapGradient(
          //   colors: [
          //     HeatmapGradientColor(Colors.green, 0.2),
          //     HeatmapGradientColor(Colors.red, 0.8),
          //   ],
          // ),
        ),
      );
    });
  }
}

