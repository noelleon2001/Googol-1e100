import 'package:google_maps_flutter/google_maps_flutter.dart';

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