import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';

class EnRouteScreen extends StatefulWidget {
  const EnRouteScreen({super.key});

  @override
  State<EnRouteScreen> createState() => _EnRouteScreenState();
}

class _EnRouteScreenState extends State<EnRouteScreen> {
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;
  BitmapDescriptor? _driverIcon;
  
  // Simulated current location (moving towards destination)
  LatLng _currentLocation = const LatLng(31.7738281, 35.2143664); // Start at pickup
  final LatLng _destinationLocation = const LatLng(31.7801362, 35.2181067);
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  double _distanceRemaining = 0.0;
  int _timeRemaining = 8; // minutes
  
  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
    _setupMarkers();
    _startLocationSimulation();
    _calculateInitialDistance();
  }

  void _loadCustomIcon() async {
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/driver.png',
      );
      setState(() {
        _driverIcon = icon;
        _setupMarkers();
      });
    } catch (e) {
      print('Error loading driver icon: $e');
    }
  }

  void _calculateInitialDistance() {
    setState(() {
      _distanceRemaining = _calculateDistance(_currentLocation, _destinationLocation);
    });
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadiusKm = 6371;
    
    final double dLat = _degreesToRadians(to.latitude - from.latitude);
    final double dLon = _degreesToRadians(to.longitude - from.longitude);
    
    final double a = 
      (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      (math.cos(_degreesToRadians(from.latitude)) * 
       math.cos(_degreesToRadians(to.latitude)) *
       math.sin(dLon / 2) * math.sin(dLon / 2));
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _setupMarkers() {
    setState(() {
      _markers = {
        // Current location (driver with passenger)
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Your ride'),
          icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
        // Destination marker
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
      
      // Draw route line
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_currentLocation, _destinationLocation],
          color: AppColors.primary,
          width: 5,
        ),
      };
    });
  }

  void _startLocationSimulation() {
    // Simulate moving towards destination
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        // Move towards destination
        double latDiff = (_destinationLocation.latitude - _currentLocation.latitude) * 0.1;
        double lngDiff = (_destinationLocation.longitude - _currentLocation.longitude) * 0.1;
        
        _currentLocation = LatLng(
          _currentLocation.latitude + latDiff,
          _currentLocation.longitude + lngDiff,
        );
        
        // Update distance and time
        _distanceRemaining = _calculateDistance(_currentLocation, _destinationLocation);
        _timeRemaining = (_distanceRemaining * 2).ceil(); // Rough estimate
        
        _setupMarkers();
        
        // Stop when arrived
        if (_distanceRemaining < 0.05) { // Less than 50 meters
          timer.cancel();
          _showArrivalDialog();
        }
      });
    });
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('You\'ve arrived!'),
          content: const Text('You have reached your destination. Have a great day!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, _) {
          return Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final driver = rideProvider.assignedDriver;
              
              if (driver == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return Stack(
                children: [
                  // Google Map
                  GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Top info card
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: _buildTopInfoCard(driver),
                  ),

                  // Bottom sheet
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomSheet(context, driver, rideProvider, locationProvider),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopInfoCard(dynamic driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                driver.photo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 20),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${driver.vehicleModel} • ${driver.plateNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.call, color: AppColors.white, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling driver...')),
                );
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, dynamic driver, RideProvider rideProvider, LocationProvider locationProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'En route to destination',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_timeRemaining min',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Distance and time info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  Icons.location_on_outlined,
                  '${_distanceRemaining.toStringAsFixed(1)} km',
                  'Distance',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  Icons.schedule,
                  '$_timeRemaining min',
                  'ETA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  Icons.attach_money,
                  '₪${rideProvider.estimatedFare.toStringAsFixed(2)}',
                  'Fare',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Destination address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locationProvider.dropoffLocation?.address ?? 'Destination',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
