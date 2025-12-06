import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';

class DriverSelectionScreen extends StatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  late PageController _pageController;
  GoogleMapController? _mapController;
  late LatLng _driverLocation;
  late LatLng _pickupLocation;
  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCustomIcon();
    _startDriverAnimation();
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
      // Fallback to default marker if image not found
      print('Error loading driver icon: $e');
    }
  }

  void _startDriverAnimation() {
    // Get initial locations from provider
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    if (locationProvider.pickupLocation != null && rideProvider.currentDriver != null) {
      _pickupLocation = LatLng(
        locationProvider.pickupLocation!.latitude,
        locationProvider.pickupLocation!.longitude,
      );
      _driverLocation = rideProvider.currentDriver!.currentLocation;
      
      // Animate driver towards pickup
      _animateDriverToPickup();
    }
  }

  void _animateDriverToPickup() {
    Future.doWhile(() async {
      if (!mounted) return false;
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return false;
      
      // Move driver 10% closer to pickup
      final distance = _calculateDistance(_driverLocation, _pickupLocation);
      if (distance < 0.1) return false; // Stop if very close
      
      final bearing = _calculateBearing(_driverLocation, _pickupLocation);
      _driverLocation = _moveTowards(_driverLocation, bearing, 0.05); // Move 50 meters
      
      setState(() {});
      return true;
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
    return degrees * (3.14159265359 / 180);
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double dLon = _degreesToRadians(to.longitude - from.longitude);
    final double y = math.sin(dLon) * math.cos(_degreesToRadians(to.latitude));
    final double x = math.cos(_degreesToRadians(from.latitude)) * math.sin(_degreesToRadians(to.latitude)) -
        math.sin(_degreesToRadians(from.latitude)) * math.cos(_degreesToRadians(to.latitude)) * math.cos(dLon);
    
    return math.atan2(y, x);
  }

  LatLng _moveTowards(LatLng from, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371;
    
    final double lat1 = _degreesToRadians(from.latitude);
    final double lon1 = _degreesToRadians(from.longitude);
    final double angularDistance = distanceKm / earthRadiusKm;
    
    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
      math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing)
    );
    
    final double lon2 = lon1 + math.atan2(
      math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
      math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2)
    );
    
    return LatLng(
      lat2 * (180 / 3.14159265359),
      lon2 * (180 / 3.14159265359),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
              
              // Default to Jerusalem if no location
              final initialLocation = pickupLocation != null
                  ? LatLng(pickupLocation.latitude, pickupLocation.longitude)
                  : const LatLng(31.7683, 35.2137);
              
              return Stack(
                children: [
                  // Google Map - Full screen
                  GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: initialLocation,
                      zoom: 14,
                    ),
                    markers: {
                      // Only show driver marker (moving car icon)
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: _driverLocation,
                        infoWindow: const InfoWindow(title: 'Driver arriving'),
                        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                    },
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

                  // Driver card at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
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
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Driver cards carousel
                          SizedBox(
                            height: 260,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                // Update provider when swiping
                                if (index > rideProvider.availableDrivers.indexOf(
                                  rideProvider.currentDriver ?? rideProvider.availableDrivers.first,
                                )) {
                                  rideProvider.nextDriver();
                                } else {
                                  rideProvider.previousDriver();
                                }
                              },
                              itemCount: rideProvider.availableDrivers.length,
                              itemBuilder: (context, index) {
                                final driver = rideProvider.availableDrivers[index];
                                return _buildDriverCard(context, driver, rideProvider);
                              },
                            ),
                          ),

                          // Page indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: rideProvider.availableDrivers.length,
                              effect: ExpandingDotsEffect(
                                dotColor: Colors.grey[300]!,
                                activeDotColor: AppColors.primary,
                                dotHeight: 8,
                                dotWidth: 8,
                                spacing: 8,
                              ),
                            ),
                          ),

                          // Confirm button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  rideProvider.confirmDriver();
                                  Navigator.pushNamed(context, AppRouter.activeRide);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context,
    dynamic driver,
    RideProvider rideProvider,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver info header
            Row(
              children: [
                // Driver avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
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
                const SizedBox(width: 10),

                // Driver name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${driver.rating}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat opened')),
                          );
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.call,
                          color: AppColors.white,
                          size: 16,
                        ),
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

            const SizedBox(height: 8),

            // Vehicle info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.vehicleModel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${driver.vehicleColor} • ${driver.plateNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Distance, time, price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  context,
                  Icons.location_on_outlined,
                  '${driver.distanceKm} km',
                  'Distance',
                ),
                _buildInfoColumn(
                  context,
                  Icons.schedule,
                  '${driver.etaMinutes} min',
                  'ETA',
                ),
                _buildInfoColumn(
                  context,
                  Icons.attach_money,
                  '₪${rideProvider.estimatedFare.toStringAsFixed(2)}',
                  'Price',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
