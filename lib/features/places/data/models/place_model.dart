import '../../domain/entities/geo_point.dart';
import '../../domain/entities/place.dart';

/// A place in the shape the data source provides it.
///
/// Keeping this apart from the [Place] entity means a real API's field names
/// only ever affect this file.
class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.area,
    required this.lat,
    required this.lng,
    required this.opens,
    required this.closes,
    required this.summary,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      price: json['price'] as int,
      area: json['area'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      opens: json['opens'] as int,
      closes: json['closes'] as int,
      summary: json['summary'] as String,
    );
  }

  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final int price;
  final String area;
  final double lat;
  final double lng;
  final int opens;
  final int closes;
  final String summary;

  Place toEntity() {
    final parsedCategory = PlaceCategory.values.asNameMap()[category];
    if (parsedCategory == null) {
      throw FormatException('Unknown place category: $category');
    }
    return Place(
      id: id,
      name: name,
      category: parsedCategory,
      rating: rating,
      reviewCount: reviews,
      priceLevel: price,
      neighbourhood: area,
      location: GeoPoint(lat, lng),
      opensAtHour: opens,
      closesAtHour: closes,
      summary: summary,
    );
  }
}
