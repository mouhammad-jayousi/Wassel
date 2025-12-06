import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';

class DriverArrivedScreen extends StatefulWidget {
  const DriverArrivedScreen({super.key});

  @override
  State<DriverArrivedScreen> createState() => _DriverArrivedScreenState();
}

class _DriverArrivedScreenState extends State<DriverArrivedScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _driverIcon;
  
  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  void _loadCustomIcon() async {
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/driver.png',
      );
      setState(() {
        _driverIcon = icon;
      });
    } catch (e) {
      print('Error loading driver icon: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, _) {
          return Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final pickupLocation = locationProvider.pickupLocation;
              final driver = rideProvider.assignedDriver;
              
              if (pickupLocation == null || driver == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final pickupLatLng = LatLng(pickupLocation.latitude, pickupLocation.longitude);
              
              return Stack(
                children: [
                  // Google Map
                  GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: pickupLatLng,
                      zoom: 16,
                    ),
                    markers: {
                      // Driver marker at pickup
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: pickupLatLng,
                        infoWindow: const InfoWindow(title: 'Driver is here'),
                        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                      // Pickup marker
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: pickupLatLng,
                        infoWindow: const InfoWindow(title: 'Your location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),

                  // Back button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textDark,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Bottom sheet
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomSheet(context, driver, rideProvider),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, dynamic driver, RideProvider rideProvider) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Driver has arrived and is waiting for you',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Driver info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
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
                        child: const Icon(Icons.person, size: 24),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${driver.vehicleModel} • ${driver.plateNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat opened')),
                        );
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.call, color: AppColors.white, size: 20),
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
            ],
          ),

          const SizedBox(height: 24),

          // Confirm onboard button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to onboard confirmation
                Navigator.pushReplacementNamed(context, AppRouter.onboardConfirmation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'I\'m in the car',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showCancelDialog(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Ride?'),
          content: const Text('Are you sure you want to cancel this ride? A cancellation fee may apply.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, keep ride'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );
  }
}
