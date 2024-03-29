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
    final placesData = json['results'] as List<dynamic>;

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
  final String businessStatus;
  final bool? openNow;
  final String? photoReference;
  final String? icon;
  double? rating;

  Place({
    required this.formattedAddress,
    required this.name,
    required this.latLng,
    required this.businessStatus,
    this.openNow,
    this.photoReference,
    this.icon,
    this.rating
  });

  factory Place.fromJson(Map<String, dynamic> json){
    print(json);
     var location = json['geometry']['location'] as Map<String, dynamic>,
         lat = location['lat'],
         lng = location['lng'];

    return Place(
      formattedAddress: json['formatted_address'],
      name: json['name'],
      latLng: LatLng(lat!, lng!),
      businessStatus: json['business_status'],
      openNow: json['opening_hours'] != null ? json['opening_hours']['open_now'] : null,
      photoReference: json['photos'] != null ? json['photos'][0]['photo_reference'] : null,
      icon: json['icon'],
      rating: json['rating'].toDouble(),
    );
  }
}