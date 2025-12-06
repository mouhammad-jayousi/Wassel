import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';

class LocationModel {
  final String address;
  final double latitude;
  final double longitude;
  
  LocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  LocationModel? _pickupLocation;
  LocationModel? _dropoffLocation;
  List<LocationModel> _stops = []; // Intermediate stops between pickup and dropoff
  List<LocationModel> _recentLocations = [];
  List<LocationModel> _savedPlaces = [];
  
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get pickupLocation => _pickupLocation;
  LocationModel? get dropoffLocation => _dropoffLocation;
  List<LocationModel> get stops => _stops;
  List<LocationModel> get recentLocations => _recentLocations;
  List<LocationModel> get savedPlaces => _savedPlaces;
  
  Future<void> getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied, use default location (Jerusalem)
          _setDefaultLocation();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, use default location
        _setDefaultLocation();
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Reverse geocode to get address using Google API
      String? address = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      
      if (address == null) {
        address = 'Current Location';
      }
      
      _currentLocation = LocationModel(
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _pickupLocation = _currentLocation;
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _setDefaultLocation();
    }
  }
  
  void _setDefaultLocation() {
    // Default to Jerusalem, Israel
    _currentLocation = LocationModel(
      address: 'Jerusalem, Israel',
      latitude: 31.7683,
      longitude: 35.2137,
    );
    _pickupLocation = _currentLocation;
    notifyListeners();
  }
  
  void setPickupLocation(LocationModel location) {
    _pickupLocation = location;
    _addToRecentLocations(location);
    notifyListeners();
  }
  
  void setDropoffLocation(LocationModel? location) {
    _dropoffLocation = location;
    if (location != null) {
      _addToRecentLocations(location);
    }
    notifyListeners();
  }
  
  void clearDropoffLocation() {
    _dropoffLocation = null;
    notifyListeners();
  }
  
  void addStop(LocationModel stop) {
    _stops.add(stop);
    notifyListeners();
  }
  
  void updateStop(int index, LocationModel stop) {
    if (index >= 0 && index < _stops.length) {
      _stops[index] = stop;
      notifyListeners();
    }
  }
  
  void removeStop(int index) {
    if (index >= 0 && index < _stops.length) {
      _stops.removeAt(index);
      notifyListeners();
    }
  }
  
  void clearStops() {
    _stops.clear();
    notifyListeners();
  }
  
  void _addToRecentLocations(LocationModel location) {
    _recentLocations.removeWhere((loc) => loc.address == location.address);
    _recentLocations.insert(0, location);
    if (_recentLocations.length > 5) {
      _recentLocations = _recentLocations.sublist(0, 5);
    }
  }
  
  void addSavedPlace(LocationModel location) {
    _savedPlaces.add(location);
    notifyListeners();
  }
  
  void removeSavedPlace(LocationModel location) {
    _savedPlaces.removeWhere((loc) => loc.address == location.address);
    notifyListeners();
  }
  
  Future<void> updatePickupFromCoordinates(double latitude, double longitude, {String? address}) async {
    try {
      // Use provided address if available, otherwise reverse geocode
      String? finalAddress = address;
      
      if (finalAddress == null) {
        // Reverse geocode to get address from coordinates using Google API
        finalAddress = await GeocodingService.reverseGeocode(latitude, longitude);
        
        if (finalAddress == null) {
          finalAddress = '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        }
      }
      
      _pickupLocation = LocationModel(
        address: finalAddress,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      // Fallback to coordinates
      _pickupLocation = LocationModel(
        address: address ?? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    }
  }
  
  Future<void> updateDropoffFromCoordinates(double latitude, double longitude, {String? address}) async {
    try {
      // Use provided address if available, otherwise reverse geocode
      String? finalAddress = address;
      
      if (finalAddress == null) {
        // Reverse geocode to get address from coordinates using Google API
        finalAddress = await GeocodingService.reverseGeocode(latitude, longitude);
        
        if (finalAddress == null) {
          finalAddress = '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        }
      }
      
      _dropoffLocation = LocationModel(
        address: finalAddress,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      // Fallback to coordinates
      _dropoffLocation = LocationModel(
        address: address ?? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    }
  }
}
