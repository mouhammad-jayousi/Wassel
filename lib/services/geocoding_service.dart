import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodingService {
  static const String _apiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
  static const String _geocodeBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';

  /// Convert address to coordinates (Geocoding)
  static Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        '$_geocodeBaseUrl?address=${Uri.encodeComponent(address)}&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final formattedAddress = result['formatted_address'];

          return {
            'latitude': location['lat'],
            'longitude': location['lng'],
            'address': formattedAddress,
          };
        }
      }
      
      debugPrint('Geocoding failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      return null;
    }
  }

  /// Convert coordinates to address (Reverse Geocoding)
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_geocodeBaseUrl?latlng=$latitude,$longitude&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          
          // Try to get a nice formatted address
          String address = result['formatted_address'];
          
          // Try to extract street address
          final addressComponents = result['address_components'] as List;
          List<String> addressParts = [];
          
          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('street_number') || types.contains('route')) {
              addressParts.add(component['long_name']);
            } else if (types.contains('locality')) {
              addressParts.add(component['long_name']);
            }
          }
          
          if (addressParts.isNotEmpty) {
            address = addressParts.join(', ');
          }
          
          return address;
        }
      }
      
      debugPrint('Reverse geocoding failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Search for places (restaurants, landmarks, etc.) using Places API
  static Future<List<Map<String, dynamic>>> searchPlaces(String query, {String region = 'IL'}) async {
    try {
      // Bias search to Israel/Palestine region
      final url = Uri.parse(
        '$_placesBaseUrl?query=${Uri.encodeComponent(query)}&region=$region&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          
          return results.map<Map<String, dynamic>>((result) {
            final location = result['geometry']['location'];
            return {
              'name': result['name'] ?? '',
              'address': result['formatted_address'] ?? '',
              'latitude': location['lat'],
              'longitude': location['lng'],
              'types': result['types'] ?? [],
            };
          }).toList();
        }
      }
      
      debugPrint('Places search failed: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }
}
