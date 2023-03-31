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
import 'package:custom_info_window/custom_info_window.dart';
import 'package:map_launcher/map_launcher.dart' as mpl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../models.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  static const List<String> markerOptions = [
    'Recycling Centres',
    'Waste Collectors',
    'Heatmap'
  ];

  @override
  State<MapView> createState() => _MapViewState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  late gs.GoogleMapsPlaces places;

  final firestoreRef = FirebaseFirestore.instance;
  QuerySnapshot? _list;
  List<WeightedLatLng> heatmapPoints = [];

  Location location = Location();
  LocationData? _currentLocationData;
  LatLng? currentLatLng;

  final Mode _mode = Mode.overlay;
  String dropDownValue = MapView.markerOptions.first;

  Set<Marker> markers = {};
  Set<Heatmap> heatmaps = {};

  bool isPhoto = false;

  @override
  void initState() {
    super.initState();
    initPlaces();
    getLocation();
    getHeatmapPoints();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _customInfoWindowController.googleMapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return currentLatLng == null
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(title: Text('Map'), actions: [
              Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: _mapOpen,
                  child: Icon(Icons.map_outlined),
                ),
              ),
            ]),
            key: homeScaffoldKey,
            body: SafeArea(
              child: Stack(children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onTap: (position) {
                    _customInfoWindowController.hideInfoWindow!();
                  },
                  onCameraMove: (position) {
                    _customInfoWindowController.onCameraMove!();
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentLatLng!,
                    zoom: 14.0,
                  ),
                  heatmaps: heatmaps,
                  myLocationEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: markers,
                  compassEnabled: false,
                ),
                CustomInfoWindow(
                  controller: _customInfoWindowController,
                  height: isPhoto ? 230 : 130,
                  width: 300,
                  offset: 50,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7)),
                    child: DropdownButton(
                      value: dropDownValue,
                      items: MapView.markerOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem(
                            value: value, child: Text(value));
                      }).toList(),
                      elevation: 16,
                      onChanged: (String? value) {
                        _customInfoWindowController.hideInfoWindow!();
                        setState(() {
                          dropDownValue = value!;
                        });
                        if (value != 'Heatmap') {
                          heatmaps.clear();
                          findPlaces(dropDownValue);
                        } else {
                          markers.clear();
                          fetchHeatmaps();
                        }
                      },
                    ),
                  ),
                )
              ]),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _handleSearch, child: const Icon(Icons.search)),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
          );
  }

  initPlaces() async {
    places = gs.GoogleMapsPlaces(
        apiKey: dotenv.env['GMAP_KEY'],
        apiHeaders: await const GoogleApiHeaders().getHeaders());
  }

  /*Called on init state*/
  getLocation() async {
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

    _currentLocationData = await location.getLocation();

    if (_currentLocationData != null) {
      currentLatLng = LatLng(
          _currentLocationData!.latitude!, _currentLocationData!.longitude!);
      location.onLocationChanged.listen((LocationData currentLocation) {
        if (mounted) {
          setState(() {
            _currentLocationData = currentLocation;
            currentLatLng =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
        }
        ;
      });
    }

    findPlaces(dropDownValue);
  }

  getHeatmapPoints() async {
    QuerySnapshot firebaseRes = await firestoreRef.collection('dataset').get();

    firebaseRes.docs.forEach((doc) {
      heatmapPoints.add(WeightedLatLng(
          LatLng(doc["location"].latitude, doc["location"].longitude),
          weight: 1.0));
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    _customInfoWindowController.dispose();
    super.dispose();
  }

  void _mapOpen() async {
    var mapAvailable = await mpl.MapLauncher.isMapAvailable(mpl.MapType.google);

    if (mapAvailable != null && mapAvailable == true) {
      await mpl.MapLauncher.showMarker(
          mapType: mpl.MapType.google,
          coords: mpl.Coords(currentLatLng!.latitude, currentLatLng!.longitude),
          title: 'Current Location');
    }
  }

  /*
  Sets markers
  * */
  void findPlaces(String query) async {
    if (_currentLocationData == null) {
      return;
    }

    var url =
        Uri.https('maps.googleapis.com', 'maps/api/place/textsearch/json', {
      'query': query,
      'radius': '5000',
      'location':
          '${_currentLocationData!.latitude},${_currentLocationData!.longitude}',
      'key': dotenv.env['GMAP_KEY']
    });
    var response = await http.post(url);

    Set<Marker> markers = <Marker>{};

    if (response.statusCode == 200) {
      MapResponse mapResponse = MapResponse.fromJSON(jsonDecode(response.body));
      dev.log('MapResponse: ${mapResponse.status}');

      mapResponse.places.forEach((place) => {
            markers.add(Marker(
                markerId: MarkerId(place.name),
                position: place.latLng,
                onTap: () async {
                  addInfoWindowOnMarkers(
                      place.photoReference,
                      place.latLng,
                      place.name,
                      place.rating.toString(),
                      place.openNow,
                      place.formattedAddress);
                }))
          });
    }
    setState(() => {this.markers = markers});
  }

  void addInfoWindowOnMarkers(
      photoReference, latLng, name, rating, openNow, formattedAddress) async {
    // check if has photo
    setState(() {
      isPhoto = photoReference != null ? true : false;
    });

    // for offseting the camera to make space for info window
    ScreenCoordinate screenCoordinate =
        await mapController.getScreenCoordinate(latLng);
    LatLng newCameraPosition = await mapController.getLatLng(
      ScreenCoordinate(
        x: screenCoordinate.x,
        y: isPhoto ? screenCoordinate.y - 550 : screenCoordinate.y - 300,
      ),
    );
    mapController.animateCamera(CameraUpdate.newLatLng(newCameraPosition));

    // add info window
    _customInfoWindowController.addInfoWindow!(
        Container(
          height: 350,
          width: 200,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              photoReference != null
                  ? Container(
                      height: 100,
                      width: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: getImage(photoReference),
                            fit: BoxFit.fitWidth,
                            filterQuality: FilterQuality.high),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10)),
                      ))
                  : Container(width: 0, height: 0),
              Padding(
                  padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                              width: 220,
                              child: Text(name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  softWrap: true)),
                          const Spacer(),
                          Text(rating),
                          Icon(Icons.star_rounded, color: Colors.amberAccent)
                        ],
                      ),
                      SizedBox(height: 2.5),
                      Text(
                        openNow == true ? 'Open Now' : 'Closed',
                        style: TextStyle(
                            color: openNow == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5.0),
                      Text(formattedAddress,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          softWrap: true),
                    ],
                  ))
            ],
          ),
        ),
        latLng);
  }

  ImageProvider<Object> getImage(photoReference) {
    String photoUrl =
        places.buildPhotoUrl(photoReference: photoReference, maxWidth: 400);
    return Image.network(photoUrl).image;
  }

  Future<void> _handleSearch() async {
    _customInfoWindowController.hideInfoWindow!();
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
                borderSide: BorderSide(width: 3, style: BorderStyle.none))),
        components: [gs.Component(gs.Component.country, "my")]);

    if (p != null) {
      markSearchLocation(p, homeScaffoldKey.currentState);
    }
  }

  void onSearchError(gs.PlacesAutocompleteResponse response) {
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

  Future<void> markSearchLocation(
      gs.Prediction p, ScaffoldState? currentState) async {
    gs.PlacesDetailsResponse res = await places.getDetailsByPlaceId(p.placeId!);

    gs.PlaceDetails details = res.result;

    final lat = res.result.geometry!.location.lat;
    final lng = res.result.geometry!.location.lng;

    markers.clear();
    markers.add(Marker(
        markerId: MarkerId("0"),
        position: LatLng(lat, lng),
        onTap: () {
          addInfoWindowOnMarkers(
              details.photos != null ? details.photos[0].photoReference : null,
              LatLng(lat, lng),
              details.name,
              details.rating.toString(),
              details.openingHours != null
                  ? details.openingHours!.openNow
                  : null,
              details.formattedAddress);
        }));

    setState(() {});

    mapController
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }

  void fetchHeatmaps() {
    setState(() {
      heatmaps.add(
        Heatmap(
          heatmapId: HeatmapId('0'),
          data: heatmapPoints,
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
