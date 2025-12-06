import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final Function(LatLng)? onMapDragged;
  final Function(GoogleMapController)? onMapCreated;
  final LatLng? initialPosition;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final bool showMyLocationButton;

  const MapWidget({
    super.key,
    this.onMapDragged,
    this.onMapCreated,
    this.initialPosition,
    this.markers,
    this.polylines,
    this.showMyLocationButton = true,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(31.7683, 35.2137); // Jerusalem default
  LatLng? _lastCenter;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _currentCenter = widget.initialPosition!;
      _lastCenter = widget.initialPosition!;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentCenter),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentCenter,
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onCameraMoveStarted: () {
        _isDragging = true;
      },
      onCameraMove: (CameraPosition position) {
        _currentCenter = position.target;
      },
      onCameraIdle: () {
        // Only call onMapDragged if the center actually changed significantly (dragging, not zooming)
        if (_isDragging && _lastCenter != null) {
          final distance = _calculateDistance(_lastCenter!, _currentCenter);
          // Only trigger if moved more than 10 meters (to ignore zoom)
          if (distance > 10) {
            widget.onMapDragged?.call(_currentCenter);
            _lastCenter = _currentCenter;
          }
        }
        _isDragging = false;
      },
      markers: widget.markers ?? {},
      polylines: widget.polylines ?? {},
      myLocationEnabled: true,
      myLocationButtonEnabled: widget.showMyLocationButton,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      buildingsEnabled: true,
      trafficEnabled: false,
      mapType: MapType.normal,
      style: _mapStyle,
    );
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // Custom map style (optional - makes it look more modern)
  static const String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
