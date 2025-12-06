import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../providers/location_provider.dart';
import '../../providers/saved_addresses_provider.dart';
import '../../services/geocoding_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();
  late TabController _tabController;
  bool _isSearchingPickup = false;
  bool _isSearchingDestination = false;
  String _editingField = 'pickup'; // 'pickup' or 'destination'
  List<Map<String, String>> _searchResults = [];
  bool _isLoadingResults = false;
  
  // Stops management
  List<Map<String, dynamic>> _stops = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to rebuild tabs when index changes
    _tabController.addListener(() {
      setState(() {});
    });
    
    _pickupController.addListener(() {
      setState(() {
        _isSearchingPickup = _pickupController.text.isNotEmpty;
      });
    });
    _destinationController.addListener(() {
      setState(() {
        _isSearchingDestination = _destinationController.text.isNotEmpty;
      });
    });
    
    // Auto-focus the correct field and populate existing addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // Load existing stops from LocationProvider
      if (locationProvider.stops.isNotEmpty) {
        setState(() {
          _stops = locationProvider.stops.map((stop) {
            final controller = TextEditingController(text: stop.address);
            return {
              'controller': controller,
              'focus': FocusNode(),
            };
          }).toList();
        });
      }
      
      // Populate existing addresses when editing
      if (locationProvider.pickupLocation != null) {
        _pickupController.text = locationProvider.pickupLocation!.address;
      }
      if (locationProvider.dropoffLocation != null) {
        _destinationController.text = locationProvider.dropoffLocation!.address;
      }
      
      if (args != null && args.containsKey('editingField')) {
        final field = args['editingField'] as String;
        if (field == 'pickup') {
          _pickupFocus.requestFocus();
        } else if (field.startsWith('stop_')) {
          // Editing a stop - populate the stop field with stop address
          final stopIndex = int.parse(field.split('_')[1]);
          if (stopIndex < _stops.length) {
            _stops[stopIndex]['focus'].requestFocus();
          }
        } else {
          _destinationFocus.requestFocus();
        }
      }
    });
  }
  

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocus.dispose();
    _destinationFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the editing field from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('editingField')) {
      _editingField = args['editingField'] as String;
    }
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choose route'),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_stops.isEmpty) ...[
            // Pickup Location with Plus Icon
            Padding(
              padding: const EdgeInsets.only(left: 0, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildPickupLocation()),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addStop,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textDark,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Destination Search Field
            _buildSearchField(),
          ] else ...[
            // Simple list when stops exist (no ReorderableListView to avoid errors)
            // Pickup Location with Plus Icon
            Padding(
              padding: const EdgeInsets.only(left: 0, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildPickupLocation()),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addStop,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textDark,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Stops
            ..._stops.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> stop = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildStopLocationReorderable(index, stop),
              );
            }).toList(),
            
            const SizedBox(height: 8),
            
            // Destination Search Field
            _buildSearchField(),
          ],
          
          const SizedBox(height: 16),
          
          // Tabs (only show when not searching)
          if (!_isSearchingPickup && !_isSearchingDestination && !_editingField.startsWith('stop_'))
            _buildTabs(),
          
          // Search Results / Suggestions
          Expanded(
            child: (_editingField == 'pickup' && _isSearchingPickup) || 
                   (_editingField == 'destination' && _isSearchingDestination) ||
                   (_editingField.startsWith('stop_') && _searchResults.isNotEmpty)
                   ? _buildSearchResults() : _buildSuggestions(),
          ),
        ],
      ),
    );
  }


  Widget _buildPickupLocation() {
    final isActive = _pickupController.text.isNotEmpty;
    final isFocused = _pickupFocus.hasFocus;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isFocused ? AppColors.white : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.primary : AppColors.divider,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 12),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                focusNode: _pickupFocus,
                controller: _pickupController,
                decoration: const InputDecoration(
                  hintText: 'Where from?',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: false,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
                onTap: () {
                  setState(() {
                    _editingField = 'pickup';
                  });
                },
                onChanged: (value) {
                  _performSearch(value);
                },
              ),
            ),
            if (isFocused && isActive) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Clear the text field
                  _pickupController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
            if (isFocused) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Navigate back to map to choose pickup location
                  Navigator.pop(context);
                },
                child: Image.asset(
                  'assets/images/pickup-map-icon.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addStop() {
    // Limit to 3 stops maximum
    if (_stops.length >= 3) {
      return;
    }
    setState(() {
      _stops.add({
        'controller': TextEditingController(),
        'focus': FocusNode(),
      });
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stops[index]['controller'].dispose();
      _stops[index]['focus'].dispose();
      _stops.removeAt(index);
    });
  }

  // Removed _onReorder and _buildReorderableItem - no longer using ReorderableListView to avoid paint order errors

  Widget _buildStopLocationReorderable(int index, Map<String, dynamic> stop) {
    return _buildStopLocation(index, stop);
  }

  Widget _buildStopLocation(int index, Map<String, dynamic> stop) {
    final TextEditingController controller = stop['controller'];
    final FocusNode focus = stop['focus'];
    final isActive = controller.text.isNotEmpty;
    final isFocused = focus.hasFocus;
    
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isFocused ? AppColors.white : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        focusNode: focus,
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Add stop',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                        onTap: () {
                          setState(() {
                            _editingField = 'stop_$index';
                          });
                        },
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                    if (isFocused && isActive) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          controller.clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                    if (isFocused) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/images/pickup-map-icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    ReorderableDragStartListener(
                      index: index + 1,
                      child: const Icon(
                        Icons.drag_indicator,
                        color: AppColors.textMedium,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _removeStop(index),
            child: const Icon(
              Icons.remove,
              color: AppColors.textDark,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final isActive = _destinationController.text.isNotEmpty;
    final isFocused = _destinationFocus.hasFocus;
    
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isFocused ? AppColors.white : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/destenation icon.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        focusNode: _destinationFocus,
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          hintText: 'Where to?',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                        onTap: () {
                          setState(() {
                            _editingField = 'destination';
                          });
                        },
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                    if (isFocused && isActive) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _destinationController.clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                    if (isFocused) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/images/dropoff-map-icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                    if (_stops.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.drag_indicator,
                        color: AppColors.textMedium,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_stops.isNotEmpty)
            GestureDetector(
              onTap: () {
                // TODO: Remove destination or last stop
              },
              child: const Icon(
                Icons.remove,
                color: AppColors.textDark,
                size: 28,
              ),
            )
          else
            GestureDetector(
              onTap: () {
                // Swap pickup and destination
                final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                
                // Swap the text in controllers
                final tempText = _pickupController.text;
                _pickupController.text = _destinationController.text;
                _destinationController.text = tempText;
                
                // Swap the actual locations in LocationProvider
                final tempLocation = locationProvider.pickupLocation;
                locationProvider.setPickupLocation(locationProvider.dropoffLocation!);
                locationProvider.setDropoffLocation(tempLocation!);
                
                // This will trigger route redraw
                setState(() {});
              },
              child: const Icon(
                Icons.swap_vert,
                color: AppColors.textDark,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 38,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _tabController.animateTo(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _tabController.index == 0 
                    ? AppColors.primary.withOpacity(0.04) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _tabController.index == 0 ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: _tabController.index == 0 
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: _tabController.index == 0 ? AppColors.primary : AppColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tabController.index == 0 ? AppColors.primary : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _tabController.animateTo(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _tabController.index == 1 
                    ? AppColors.primary.withOpacity(0.04) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _tabController.index == 1 ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: _tabController.index == 1 
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: _tabController.index == 1 ? AppColors.primary : AppColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Favourites',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tabController.index == 1 ? AppColors.primary : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _tabController.animateTo(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _tabController.index == 2 
                    ? AppColors.primary.withOpacity(0.04) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _tabController.index == 2 ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: _tabController.index == 2 
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    size: 16,
                    color: _tabController.index == 2 ? AppColors.primary : AppColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Airports',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tabController.index == 2 ? AppColors.primary : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No locations found'),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _searchResults.map((result) {
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(result['title'] ?? ''),
          subtitle: Text(result['subtitle'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.star_border, color: AppColors.textMedium),
            onPressed: () {
              // TODO: Add to favourites
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to favourites'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          onTap: () async {
            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
            final latitude = double.tryParse(result['latitude'] ?? '0') ?? 0;
            final longitude = double.tryParse(result['longitude'] ?? '0') ?? 0;
            final address = result['title'] ?? '';
            
            if (_editingField == 'pickup') {
              _pickupController.text = address;
              // Update pickup location with the original place name
              print('Updating pickup: $address at ($latitude, $longitude)');
              locationProvider.updatePickupFromCoordinates(latitude, longitude, address: address);
              
              // Only navigate back if BOTH pickup and destination are set
              if (_destinationController.text.isNotEmpty && locationProvider.dropoffLocation != null) {
                Navigator.pop(context);
              } else {
                // Stay on this screen and focus destination field
                setState(() {
                  _searchResults = [];
                  _editingField = 'destination';
                });
                _destinationFocus.requestFocus();
              }
            } else if (_editingField.startsWith('stop_')) {
              // Handle stop selection
              final stopIndex = int.parse(_editingField.split('_')[1]);
              final stop = LocationModel(
                address: address,
                latitude: latitude,
                longitude: longitude,
              );
              
              // Update the stop in provider
              if (stopIndex < locationProvider.stops.length) {
                locationProvider.updateStop(stopIndex, stop);
              } else {
                locationProvider.addStop(stop);
              }
              
              // Update the local controller
              if (stopIndex < _stops.length) {
                _stops[stopIndex]['controller'].text = address;
              }
              
              // Stay on this screen, don't navigate back yet
              setState(() {
                _searchResults = [];
              });
            } else {
              _destinationController.text = address;
              // Update destination location with the original place name
              print('Updating destination: $address at ($latitude, $longitude)');
              locationProvider.updateDropoffFromCoordinates(latitude, longitude, address: address);
              // Navigate back to home screen - the RideSelectionBottomSheet will show automatically
              Navigator.pop(context);
            }
            
            setState(() {
              _searchResults = [];
            });
          },
        );
      }).toList(),
    );
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoadingResults = true;
      });
    }
    
    try {
      List<Map<String, String>> results = [];
      
      // First, try Places API for restaurants, landmarks, etc.
      final placesResults = await GeocodingService.searchPlaces(query, region: 'IL');
      
      if (placesResults.isNotEmpty) {
        // Add places results
        for (var place in placesResults.take(5)) {
          results.add({
            'title': place['name'] ?? '',
            'subtitle': place['address'] ?? '',
            'latitude': place['latitude'].toString(),
            'longitude': place['longitude'].toString(),
          });
        }
      }
      
      // Then, try geocoding for street addresses
      final searchQuery = query.contains(',') ? query : '$query, Israel';
      try {
        final List<Location> locations = await locationFromAddress(searchQuery);
        
        if (locations.isNotEmpty) {
          // Get the first location
          final firstLocation = locations.first;
        
        // Get placemarks for the first location
        try {
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            firstLocation.latitude,
            firstLocation.longitude,
          );
          
          // Add the main result
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final title = placemark.street != null && placemark.street!.isNotEmpty
                ? '${placemark.street}, ${placemark.locality}'
                : placemark.locality ?? 'Location';
            final subtitle = '${placemark.administrativeArea}, ${placemark.country}';
            
            results.add({
              'title': title,
              'subtitle': subtitle,
              'latitude': firstLocation.latitude.toString(),
              'longitude': firstLocation.longitude.toString(),
            });
          }
          
          // Generate nearby results by adding small offsets
          final offsets = [
            {'lat': 0.01, 'lng': 0.0},
            {'lat': -0.01, 'lng': 0.0},
            {'lat': 0.0, 'lng': 0.01},
            {'lat': 0.0, 'lng': -0.01},
            {'lat': 0.005, 'lng': 0.005},
            {'lat': -0.005, 'lng': -0.005},
            {'lat': 0.015, 'lng': 0.0},
            {'lat': -0.015, 'lng': 0.0},
            {'lat': 0.0, 'lng': 0.015},
          ];
          
          for (var offset in offsets) {
            if (results.length >= 10) break;
            
            try {
              final nearbyLat = firstLocation.latitude + (offset['lat'] as double);
              final nearbyLng = firstLocation.longitude + (offset['lng'] as double);
              
              final nearbyPlacemarks = await placemarkFromCoordinates(nearbyLat, nearbyLng);
              
              if (nearbyPlacemarks.isNotEmpty) {
                final placemark = nearbyPlacemarks.first;
                final title = placemark.street != null && placemark.street!.isNotEmpty
                    ? '${placemark.street}, ${placemark.locality}'
                    : placemark.locality ?? 'Location';
                final subtitle = '${placemark.administrativeArea}, ${placemark.country}';
                
                // Avoid duplicates
                if (!results.any((r) => r['title'] == title)) {
                  results.add({
                    'title': title,
                    'subtitle': subtitle,
                    'latitude': nearbyLat.toString(),
                    'longitude': nearbyLng.toString(),
                  });
                }
              }
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          print('Placemark error: $e');
        }
        }
      } catch (e) {
        print('Geocoding error: $e');
      }
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingResults = false;
        });
      }
    }
  }

  Widget _buildSuggestions() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Suggestions Tab
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Use current location (only for pickup)
            if (_editingField == 'pickup')
              _buildLocationItem(
                icon: Icons.my_location,
                title: 'Use current location',
                subtitle: 'Get your current GPS location',
                onTap: () => _useCurrentLocation(),
              ),
            // TODO: Add previous trip destinations from user history
            _buildLocationItem(
              icon: Icons.home_outlined,
              title: 'Home',
              subtitle: 'Add home address',
              onTap: () {},
            ),
            _buildLocationItem(
              icon: Icons.work_outline,
              title: 'Add work',
              subtitle: '',
              onTap: () {},
            ),
          ],
        ),
        
        // Favourites Tab - Show Saved Addresses
        Consumer<SavedAddressesProvider>(
          builder: (context, savedAddressesProvider, child) {
            if (savedAddressesProvider.savedAddresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved addresses yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: savedAddressesProvider.savedAddresses.map((address) {
                return _buildLocationItem(
                  icon: _getIconForLabel(address.label),
                  title: address.label,
                  subtitle: address.address,
                  onTap: () => _selectSavedAddress(address),
                );
              }).toList(),
            );
          },
        ),
        
        // Airports Tab
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLocationItem(
              icon: Icons.flight,
              title: 'Ben Gurion Airport',
              subtitle: 'Tel Aviv',
              onTap: () => _selectLocation('Ben Gurion Airport, Tel Aviv'),
            ),
            _buildLocationItem(
              icon: Icons.flight,
              title: 'Ramon Airport',
              subtitle: 'Eilat',
              onTap: () => _selectLocation('Ramon Airport, Eilat'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}';
        
        setState(() {
          _pickupController.text = address;
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get current location. Please check permissions.'),
        ),
      );
    }
  }

  Future<void> _selectLocation(String address) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    try {
      // Geocode address to get coordinates using Google API
      final result = await GeocodingService.geocodeAddress(address);
      
      if (result != null) {
        locationProvider.setDropoffLocation(
          LocationModel(
            address: result['address'],
            latitude: result['latitude'],
            longitude: result['longitude'],
          ),
        );
        
        // Navigate back to home to show route
        Navigator.pop(context);
      } else {
        // Fallback to default Jerusalem coordinates
        locationProvider.setDropoffLocation(
          LocationModel(
            address: address,
            latitude: 31.7683,
            longitude: 35.2137,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      // Fallback to default Jerusalem coordinates
      locationProvider.setDropoffLocation(
        LocationModel(
          address: address,
          latitude: 31.7683,
          longitude: 35.2137,
        ),
      );
      Navigator.pop(context);
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'office':
        return Icons.business_outlined;
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'airport':
        return Icons.flight_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Future<void> _selectSavedAddress(dynamic address) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    if (_editingField == 'pickup') {
      _pickupController.text = address.address;
      locationProvider.updatePickupFromCoordinates(
        address.latitude,
        address.longitude,
        address: address.address,
      );
      
      // Only navigate back if BOTH pickup and destination are set
      if (_destinationController.text.isNotEmpty && locationProvider.dropoffLocation != null) {
        Navigator.pop(context);
      } else {
        // Stay on this screen and focus destination field
        setState(() {
          _searchResults = [];
          _editingField = 'destination';
        });
        _destinationFocus.requestFocus();
      }
    } else if (_editingField.startsWith('stop_')) {
      // Handle stop selection
      final stopIndex = int.parse(_editingField.split('_')[1]);
      final stop = LocationModel(
        address: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
      );
      
      // Update the stop in provider
      if (stopIndex < locationProvider.stops.length) {
        locationProvider.updateStop(stopIndex, stop);
      } else {
        locationProvider.addStop(stop);
      }
      
      // Update the local controller
      if (stopIndex < _stops.length) {
        _stops[stopIndex]['controller'].text = address.address;
      }
      
      // Stay on this screen, don't navigate back yet
      setState(() {
        _searchResults = [];
      });
    } else {
      _destinationController.text = address.address;
      locationProvider.updateDropoffFromCoordinates(
        address.latitude,
        address.longitude,
        address: address.address,
      );
      // Navigate back to home screen - the RideSelectionBottomSheet will show automatically
      Navigator.pop(context);
    }
    
    setState(() {
      _searchResults = [];
    });
  }
}
