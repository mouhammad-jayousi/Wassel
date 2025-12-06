import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  Timer? _driverUpdateTimer;
  BitmapDescriptor? _driverIcon;
  
  // Driver location (simulated movement)
  LatLng _driverLocation = const LatLng(31.7683, 35.2137);
  final LatLng _pickupLocation = const LatLng(31.7738281, 35.2143664);
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Ride details
  String _rideStatus = 'arriving'; // arriving, picked_up, in_transit
  int _estimatedArrival = 4; // minutes
  
  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
    _setupMarkers();
    _startDriverSimulation();
  }

  void _loadCustomIcon() async {
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/driver.png',
      );
      setState(() {
        _driverIcon = icon;
        _setupMarkers(); // Refresh markers with new icon
      });
    } catch (e) {
      // Fallback to default marker if image not found
      print('Error loading driver icon: $e');
    }
  }
  
  @override
  void dispose() {
    _driverUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _setupMarkers() {
    setState(() {
      _markers = {
        // Driver marker (custom driver icon)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation,
          infoWindow: const InfoWindow(title: 'Driver'),
          icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
        // Pickup marker (primary pink color pin)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      };
      
      // Draw route line (only to pickup, not to destination)
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation, _pickupLocation],
          color: AppColors.primary,
          width: 5,
        ),
      };
    });
  }
  
  double _calculateDriverDistance() {
    // Calculate distance between driver and pickup using Haversine formula
    const double earthRadiusKm = 6371;
    
    final double dLat = _degreesToRadians(_pickupLocation.latitude - _driverLocation.latitude);
    final double dLon = _degreesToRadians(_pickupLocation.longitude - _driverLocation.longitude);
    
    final double a = 
      (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      (math.cos(_degreesToRadians(_driverLocation.latitude)) * 
       math.cos(_degreesToRadians(_pickupLocation.latitude)) *
       math.sin(dLon / 2) * math.sin(dLon / 2));
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _startDriverSimulation() {
    // Simulate driver moving towards pickup
    _driverUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        // Move driver slightly towards pickup
        double latDiff = (_pickupLocation.latitude - _driverLocation.latitude) * 0.1;
        double lngDiff = (_pickupLocation.longitude - _driverLocation.longitude) * 0.1;
        
        _driverLocation = LatLng(
          _driverLocation.latitude + latDiff,
          _driverLocation.longitude + lngDiff,
        );
        
        // Update ETA
        if (_estimatedArrival > 0) {
          _estimatedArrival--;
        }
        
        _setupMarkers();
        
        // Check if driver arrived at pickup
        if (_calculateDriverDistance() < 0.05) { // Less than 50 meters
          timer.cancel();
          _navigateToDriverArrived();
        }
      });
    });
  }

  void _navigateToDriverArrived() {
    Navigator.pushReplacementNamed(context, AppRouter.driverArrived);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, _) {
          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _driverLocation,
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
              
              // Top driver info card
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: _buildDriverCard(rideProvider),
              ),
              
              // Bottom ride details sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildRideDetailsSheet(rideProvider),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDriverCard(RideProvider rideProvider) {
    final driver = rideProvider.assignedDriver;
    if (driver == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver photo
          Container(
            width: 56,
            height: 56,
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
                    child: const Icon(Icons.person),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.primary, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${driver.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      driver.vehicleModel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        driver.plateNumber,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Call button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: AppColors.white, size: 20),
              onPressed: () {
                // Call driver
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRideDetailsSheet(RideProvider rideProvider) {
    return Container(
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
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Status and ETA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rideStatus == 'arriving' ? 'Driver is arriving' : 'On the way',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_calculateDriverDistance().toStringAsFixed(1)} km away • $_estimatedArrival min',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_estimatedArrival min',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Route info
                _buildRouteInfo(rideProvider),
                
                const SizedBox(height: 20),
                
                // Ride details
                _buildRideDetails(rideProvider),
                
                const SizedBox(height: 20),
                
                // Cancel button
                OutlinedButton(
                  onPressed: () {
                    _showCancelDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Ride',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteInfo(RideProvider rideProvider) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final pickupAddress = locationProvider.pickupLocation?.address ?? 'Pickup Location';
        final dropoffAddress = locationProvider.dropoffLocation?.address ?? 'Dropoff Location';
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickupAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Container(
                      width: 1,
                      height: 20,
                      color: AppColors.divider,
                    ),
                    const SizedBox(width: 11),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dropoffAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildRideDetails(RideProvider rideProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Ride Type', rideProvider.selectedRideType?.name ?? 'Standard'),
          const SizedBox(height: 12),
          _buildDetailRow('Payment', 'Cash'),
          const SizedBox(height: 12),
          _buildDetailRow('Price', '₪${rideProvider.estimatedFare.toStringAsFixed(2)}', isPrice: true),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPrice ? FontWeight.w700 : FontWeight.w600,
            color: isPrice ? AppColors.primary : AppColors.textDark,
          ),
        ),
      ],
    );
  }
  
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Ride?'),
          content: const Text('Are you sure you want to cancel this ride? A cancellation fee may apply.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Ride'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to home
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Ride'),
            ),
          ],
        );
      },
    );
  }
}
