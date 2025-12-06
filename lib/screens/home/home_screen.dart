import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/ride_selection_bottom_sheet.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  
  const HomeScreen({super.key, this.onMenuPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isMapDragging = false;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Route information with traffic
  double? _routeDistanceKm;
  double? _routeDurationMinutes;
  
  // Save reference to provider for safe disposal
  LocationProvider? _locationProvider;
  
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to provider for safe disposal
    if (_locationProvider == null) {
      _locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _locationProvider!.addListener(_onLocationChanged);
    }
  }

  Future<void> _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();
    _updateMarkers();
  }
  
  void _onLocationChanged() {
    // Only update markers, don't change map position
    _updateMarkers();
  }
  
  @override
  void dispose() {
    // Safe to use saved reference in dispose
    _locationProvider?.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _recenterToUserLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation != null) {
      final position = LatLng(
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(position),
      );
      
      setState(() {
        _isMapDragging = false;
      });
    }
  }

  void _onMapDragged(LatLng center) {
    setState(() {
      _isMapDragging = false;
    });
    
    // Don't update pickup location automatically when dragging
    // User can update it manually by selecting a location from search
  }
  
  void _updateMarkers() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    Set<Marker> markers = {};
    
    // Add pickup marker (green circle/ring)
    if (locationProvider.pickupLocation != null) {
      final pickupIcon = await _createPickupMarker();
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            locationProvider.pickupLocation!.latitude,
            locationProvider.pickupLocation!.longitude,
          ),
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: locationProvider.pickupLocation!.address,
          ),
        ),
      );
    }
    
    // Add stop markers (white circles with purple shadow)
    for (int i = 0; i < locationProvider.stops.length; i++) {
      final stop = locationProvider.stops[i];
      final stopIcon = await _createStopMarker();
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: stopIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Stop ${i + 1}',
            snippet: stop.address,
          ),
        ),
      );
    }
    
    // Add destination marker (black pin)
    if (locationProvider.dropoffLocation != null) {
      final destinationIcon = await _createDestinationMarker();
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            locationProvider.dropoffLocation!.latitude,
            locationProvider.dropoffLocation!.longitude,
          ),
          icon: destinationIcon,
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: locationProvider.dropoffLocation!.address,
          ),
        ),
      );
      
      // Draw route if both locations exist
      if (locationProvider.pickupLocation != null) {
        _drawRouteWithStops(
          locationProvider.pickupLocation!,
          locationProvider.stops,
          locationProvider.dropoffLocation!,
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  Future<BitmapDescriptor> _createPickupMarker() async {
    // Create custom pink circle marker
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 60.0;
    
    // Draw outer circle (pink)
    final outerPaint = Paint()
      ..color = AppColors.primary // Pink color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, outerPaint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);
    
    // Draw inner white circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 4, innerPaint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
  
  Future<BitmapDescriptor> _createStopMarker() async {
    // Create white circle with purple shadow for stops
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 50.0;
    
    // Draw purple shadow
    final shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3) // Purple shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size / 2, size / 2 + 2), size / 2.5, shadowPaint);
    
    // Draw white circle
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, circlePaint);
    
    // Draw purple border
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5 - 1.5, borderPaint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
  
  Future<BitmapDescriptor> _createDestinationMarker() async {
    // Create custom black pin marker
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 60.0;
    
    // Draw pin shape (black)
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // Draw circle at top
    canvas.drawCircle(Offset(size / 2, size / 3), size / 3, paint);
    
    // Draw pin point
    final path = Path();
    path.moveTo(size / 2, size);
    path.lineTo(size / 4, size / 2);
    path.lineTo(size * 3 / 4, size / 2);
    path.close();
    canvas.drawPath(path, paint);
    
    // Draw white inner circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 3), size / 6, innerPaint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
  
  /// Fetch route info with traffic from Google Directions API
  Future<Map<String, dynamic>?> _fetchRouteInfo(
    LocationModel pickup,
    List<LocationModel> stops,
    LocationModel dropoff,
  ) async {
    const String googleApiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
    
    // Build waypoints string
    String waypointsStr = '';
    if (stops.isNotEmpty) {
      waypointsStr = '&waypoints=' + stops.map((s) => '${s.latitude},${s.longitude}').join('|');
    }
    
    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${dropoff.latitude},${dropoff.longitude}'
        '$waypointsStr'
        '&mode=driving'
        '&departure_time=now' // This enables traffic data
        '&key=$googleApiKey';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Get distance in meters and duration in seconds (with traffic)
          final distanceMeters = leg['distance']['value'];
          final durationSeconds = leg['duration_in_traffic'] != null
              ? leg['duration_in_traffic']['value']
              : leg['duration']['value'];
          
          debugPrint('📊 Route info: ${distanceMeters}m, ${durationSeconds}s');
          
          return {
            'distanceKm': distanceMeters / 1000.0,
            'durationMinutes': durationSeconds / 60.0,
          };
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching route info: $e');
    }
    
    return null;
  }
  
  Future<void> _drawRouteWithStops(LocationModel pickup, List<LocationModel> stops, LocationModel dropoff) async {
    try {
      debugPrint('🗺️ Drawing route with ${stops.length} stops');
      
      // Fetch route info with traffic FIRST
      final routeInfo = await _fetchRouteInfo(pickup, stops, dropoff);
      if (routeInfo != null) {
        setState(() {
          _routeDistanceKm = routeInfo['distanceKm'];
          _routeDurationMinutes = routeInfo['durationMinutes'];
        });
        debugPrint('✅ Route: ${_routeDistanceKm?.toStringAsFixed(1)}km, ${_routeDurationMinutes?.toStringAsFixed(0)}min');
      }
      
      // Use PolylinePoints to get route
      PolylinePoints polylinePoints = PolylinePoints();
      
      // Google Maps API key
      const String googleApiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
      
      // Build waypoints from stops
      List<PolylineWayPoint> waypoints = stops.map((stop) {
        return PolylineWayPoint(location: '${stop.latitude},${stop.longitude}');
      }).toList();
      
      // Retry logic with timeout
      PolylineResult? result;
      int retries = 2;
      
      for (int i = 0; i < retries; i++) {
        try {
          result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: googleApiKey,
            request: PolylineRequest(
              origin: PointLatLng(pickup.latitude, pickup.longitude),
              destination: PointLatLng(dropoff.latitude, dropoff.longitude),
              mode: TravelMode.driving,
              wayPoints: waypoints,
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Request timeout, attempt ${i + 1}/$retries');
              throw TimeoutException('Route request timed out');
            },
          );
          
          // If successful, break the retry loop
          if (result.points.isNotEmpty) {
            break;
          }
        } catch (e) {
          debugPrint('⚠️ Attempt ${i + 1}/$retries failed: $e');
          if (i == retries - 1) {
            // Last retry failed, use fallback
            debugPrint('❌ All retries failed, using fallback route');
            _drawFallbackRouteWithStops(pickup, stops, dropoff);
            return;
          }
          // Wait before retry
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (result != null && result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        
        debugPrint('✅ Got ${polylineCoordinates.length} route points with stops');
        
        if (mounted) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: AppColors.primary,
                width: 5,
                geodesic: true,
              ),
            };
          });
        }
        
        _fitAllMarkersInView([pickup, ...stops, dropoff]);
      } else {
        debugPrint('⚠️ No route found, using fallback');
        _drawFallbackRouteWithStops(pickup, stops, dropoff);
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error drawing route: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _drawFallbackRouteWithStops(pickup, stops, dropoff);
    }
  }
  
  void _drawFallbackRouteWithStops(LocationModel pickup, List<LocationModel> stops, LocationModel dropoff) {
    debugPrint('⚠️ Using fallback straight line route with stops');
    List<LatLng> points = [
      LatLng(pickup.latitude, pickup.longitude),
      ...stops.map((stop) => LatLng(stop.latitude, stop.longitude)),
      LatLng(dropoff.latitude, dropoff.longitude),
    ];
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary, // Pink color
          width: 5,
        ),
      };
    });
    _fitAllMarkersInView([pickup, ...stops, dropoff]);
  }
  
  void _fitAllMarkersInView(List<LocationModel> locations) {
    if (locations.isEmpty) return;
    
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;
    
    for (var location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }
  
  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    try {
      debugPrint('🗺️ Drawing route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');
      
      // Use PolylinePoints to get route
      PolylinePoints polylinePoints = PolylinePoints();
      
      // Google Maps API key
      const String googleApiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );
      
      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        
        debugPrint('✅ Got ${polylineCoordinates.length} route points');
        
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: AppColors.primary, // Pink color
              width: 5,
              geodesic: true,
            ),
          };
        });
        
        _fitMarkersInView(origin, destination);
      } else {
        debugPrint('⚠️ No route found, using fallback');
        _drawFallbackRoute(origin, destination);
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error drawing route: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _drawFallbackRoute(origin, destination);
    }
  }
  
  
  void _drawFallbackRoute(LatLng origin, LatLng destination) {
    debugPrint('⚠️ Using fallback straight line route');
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [origin, destination],
          color: AppColors.primary, // Pink color
          width: 5,
        ),
      };
    });
    _fitMarkersInView(origin, destination);
  }
  
  void _fitMarkersInView(LatLng point1, LatLng point2) {
    double minLat = point1.latitude < point2.latitude ? point1.latitude : point2.latitude;
    double maxLat = point1.latitude > point2.latitude ? point1.latitude : point2.latitude;
    double minLng = point1.longitude < point2.longitude ? point1.longitude : point2.longitude;
    double maxLng = point1.longitude > point2.longitude ? point1.longitude : point2.longitude;
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          final hasDestination = locationProvider.dropoffLocation != null;
          
          return Stack(
            children: [
              // Map Container
              _buildMapView(),
              
              // Top Header
              _buildTopHeader(),
              
              // Center Pin (when dragging map)
              if (_isMapDragging) _buildCenterPin(),
              
              // Recenter Button
              _buildRecenterButton(),
              
              // Bottom Sheet - show ride selection if destination is set
              if (hasDestination)
                RideSelectionBottomSheet(
                  distanceKm: _routeDistanceKm,
                  durationMinutes: _routeDurationMinutes,
                )
              else
                _buildBottomSheet(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        LatLng? initialPosition;
        
        // Use pickup location if available, otherwise current location
        if (locationProvider.pickupLocation != null) {
          initialPosition = LatLng(
            locationProvider.pickupLocation!.latitude,
            locationProvider.pickupLocation!.longitude,
          );
          debugPrint('📍 Map initial position from pickup: $initialPosition');
        } else if (locationProvider.currentLocation != null) {
          initialPosition = LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          );
          debugPrint('📍 Map initial position from current: $initialPosition');
        } else {
          // Default to Jerusalem
          initialPosition = const LatLng(31.7683, 35.2137);
          debugPrint('📍 Map initial position default: $initialPosition');
        }
        
        return MapWidget(
          initialPosition: initialPosition,
          onMapCreated: (controller) {
            _mapController = controller;
            _updateMarkers(); // Initialize markers
          },
          onMapDragged: _onMapDragged,
          markers: _markers,
          polylines: _polylines,
          showMyLocationButton: false, // We have our own button
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final hasDestination = locationProvider.dropoffLocation != null;
        
        if (hasDestination) {
          // Show route header when destination is set
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () {
                      locationProvider.clearDropoffLocation();
                      locationProvider.clearStops();
                    },
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Route summary - clickable addresses with stops
                  Expanded(
                    child: Row(
                      children: [
                        // Pickup address (clickable) - Purple color
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.locationSearch, arguments: {'editingField': 'pickup'});
                            },
                            child: Text(
                              locationProvider.pickupLocation?.address ?? "Pickup",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary, // Purple color for pickup
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '→',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                        // Show stops if any
                        if (locationProvider.stops.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              '${locationProvider.stops.length} stop${locationProvider.stops.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '→',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ),
                        ],
                        // Destination address (clickable)
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.locationSearch, arguments: {'editingField': 'destination'});
                            },
                            child: Text(
                              locationProvider.dropoffLocation?.address ?? "Destination",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add stop button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.locationSearch, arguments: {'editingField': 'stop_${locationProvider.stops.length}'});
                    },
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Show menu button when no destination
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: AppColors.textDark,
                      ),
                      onPressed: widget.onMenuPressed ?? () {},
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildCenterPin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.white,
              size: 32,
            ),
          ),
          Container(
            width: 2,
            height: 20,
            color: AppColors.textDark,
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: 16,
      bottom: 400,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.my_location,
            color: _isMapDragging ? AppColors.primary : AppColors.textMedium,
          ),
          onPressed: _recenterToUserLocation,
        ),
      ),
    );
  }


  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Pickup Location
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRouter.locationSearch, arguments: {'editingField': 'pickup'}),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.textDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: AppColors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locationProvider.pickupLocation?.address ??
                                        locationProvider.currentLocation?.address ??
                                        'Getting location...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
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
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              // Where to? / Destination Button
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  final hasDestination = locationProvider.dropoffLocation != null;
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.locationSearch, arguments: {'editingField': 'destination'});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasDestination ? AppColors.primaryLight : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasDestination ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: hasDestination ? AppColors.primary : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: hasDestination ? AppColors.primary : AppColors.divider,
                              ),
                            ),
                            child: Icon(
                              hasDestination ? Icons.location_on : Icons.search,
                              color: hasDestination ? AppColors.white : AppColors.textDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasDestination 
                                  ? locationProvider.dropoffLocation!.address
                                  : 'Where to?',
                              style: TextStyle(
                                fontSize: 16,
                                color: hasDestination ? AppColors.textDark : AppColors.textMedium,
                                fontWeight: hasDestination ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDestination) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                locationProvider.clearDropoffLocation();
                                setState(() {
                                  _polylines.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Suggested Destinations
              const Text(
                'Suggested Destinations',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildSuggestion(
                icon: Icons.access_time,
                title: 'Derech Hizma 19',
                subtitle: 'Jerusalem',
              ),
              
              _buildSuggestion(
                icon: Icons.access_time,
                title: 'Beit Lehem Rd 75',
                subtitle: 'Jerusalem',
              ),
              
              const Divider(height: 32),
              
              _buildSuggestion(
                icon: Icons.home_outlined,
                title: 'Home',
                subtitle: 'Add home address',
                onTap: () {},
              ),
              
              _buildSuggestion(
                icon: Icons.work_outline,
                title: 'Work',
                subtitle: 'Add work address',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestion({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.textMedium,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMedium,
        ),
      ),
      onTap: onTap ?? () {
        // TODO: Navigate to location
      },
    );
  }

}
