import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

enum RideStatus {
  idle,
  searching,
  driverAvailable,
  driverConfirmed,
  driverArriving,
  driverArrived,
  rideStarted,
  rideCompleted,
  cancelled,
}

class RideType {
  final String id;
  final String name;
  final String icon;
  final double pricePerKm;
  final String estimatedPrice;
  
  RideType({
    required this.id,
    required this.name,
    required this.icon,
    required this.pricePerKm,
    required this.estimatedPrice,
  });
}

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String photo;
  final double rating;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;
  final double distanceKm;
  final int etaMinutes;
  final LatLng currentLocation;
  
  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.photo,
    required this.rating,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plateNumber,
    required this.distanceKm,
    required this.etaMinutes,
    required this.currentLocation,
  });
}

class RideProvider extends ChangeNotifier {
  RideStatus _status = RideStatus.idle;
  RideType? _selectedRideType;
  DriverModel? _assignedDriver;
  List<DriverModel> _availableDrivers = [];
  int _currentDriverIndex = 0;
  double _estimatedFare = 0.0;
  String? _promoCode;
  double _discount = 0.0;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String? _pickupAddress;
  String? _dropoffAddress;
  
  RideStatus get status => _status;
  RideType? get selectedRideType => _selectedRideType;
  DriverModel? get assignedDriver => _assignedDriver;
  List<DriverModel> get availableDrivers => _availableDrivers;
  DriverModel? get currentDriver => _currentDriverIndex < _availableDrivers.length ? _availableDrivers[_currentDriverIndex] : null;
  double get estimatedFare => _estimatedFare;
  String? get promoCode => _promoCode;
  double get discount => _discount;
  double get finalFare => _estimatedFare - _discount;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get dropoffLocation => _dropoffLocation;
  String? get pickupAddress => _pickupAddress;
  String? get dropoffAddress => _dropoffAddress;
  
  final List<RideType> availableRideTypes = [
    RideType(
      id: 'standard',
      name: 'Standard',
      icon: '🚗',
      pricePerKm: 2.5,
      estimatedPrice: '\$25.00',
    ),
    RideType(
      id: 'premium',
      name: 'Premium',
      icon: '🚙',
      pricePerKm: 3.5,
      estimatedPrice: '\$35.00',
    ),
  ];
  
  void setLocations(LatLng pickup, LatLng dropoff, {String? pickupAddr, String? dropoffAddr}) {
    _pickupLocation = pickup;
    _dropoffLocation = dropoff;
    _pickupAddress = pickupAddr;
    _dropoffAddress = dropoffAddr;
    if (_estimatedFare == 0.0) {
      _calculateFare();
    }
    notifyListeners();
  }
  
  void selectRideType(RideType rideType) {
    _selectedRideType = rideType;
    _calculateFare();
    notifyListeners();
  }
  
  void setEstimatedFare(double fare) {
    _estimatedFare = fare;
    notifyListeners();
  }
  
  void _calculateFare() {
    if (_selectedRideType != null && _pickupLocation != null && _dropoffLocation != null) {
      double distance = _calculateDistance(_pickupLocation!, _dropoffLocation!);
      double estimatedTime = (distance / 30) * 60;
      double baseFare = 12.82 + (math.max(distance, estimatedTime) * 2.01) + 2.00;
      
      if (_estimatedFare == 0.0) {
        _estimatedFare = baseFare;
      }
    } else if (_selectedRideType != null && _estimatedFare == 0.0) {
      _estimatedFare = 25.0;
    }
  }
  
  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(to.latitude - from.latitude);
    final double dLon = _degreesToRadians(to.longitude - from.longitude);
    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(from.latitude)) * 
         math.cos(_degreesToRadians(to.latitude)) *
         math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  Future<void> requestRide(String userId) async {
    _status = RideStatus.searching;
    _availableDrivers = [];
    _currentDriverIndex = 0;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _availableDrivers = [
      DriverModel(
        id: 'driver_1',
        name: 'Gregory Smith',
        phone: '+1234567890',
        photo: 'https://i.pravatar.cc/150?img=1',
        rating: 4.9,
        vehicleModel: 'Toyota Camry',
        vehicleColor: 'Black',
        plateNumber: 'ABC 1234',
        distanceKm: 0.8,
        etaMinutes: 5,
        currentLocation: LatLng(31.7683, 35.2137),
      ),
      DriverModel(
        id: 'driver_2',
        name: 'Rachel Ba-Sdera',
        phone: '+1234567891',
        photo: 'https://i.pravatar.cc/150?img=5',
        rating: 4.7,
        vehicleModel: 'Honda Civic',
        vehicleColor: 'Silver',
        plateNumber: 'XYZ 5678',
        distanceKm: 1.2,
        etaMinutes: 7,
        currentLocation: LatLng(31.7650, 35.2100),
      ),
    ];
    
    _status = RideStatus.driverAvailable;
    notifyListeners();
  }
  
  void nextDriver() {
    if (_currentDriverIndex < _availableDrivers.length - 1) {
      _currentDriverIndex++;
      notifyListeners();
    }
  }
  
  void previousDriver() {
    if (_currentDriverIndex > 0) {
      _currentDriverIndex--;
      notifyListeners();
    }
  }
  
  Future<void> confirmDriver() async {
    if (currentDriver != null) {
      _assignedDriver = currentDriver;
      _status = RideStatus.driverConfirmed;
      notifyListeners();
    }
  }
  
  void applyPromoCode(String code) {
    _promoCode = code;
    _discount = 5.0;
    notifyListeners();
  }
  
  Future<void> cancelRide(String userId) async {
    _status = RideStatus.cancelled;
    _assignedDriver = null;
    notifyListeners();
  }
  
  void startRide() {
    _status = RideStatus.rideStarted;
    notifyListeners();
  }
  
  Future<void> completeRide() async {
    _status = RideStatus.rideCompleted;
    notifyListeners();
  }
  
  void resetRide() {
    _status = RideStatus.idle;
    _selectedRideType = null;
    _assignedDriver = null;
    _estimatedFare = 0.0;
    _promoCode = null;
    _discount = 0.0;
    notifyListeners();
  }
}
