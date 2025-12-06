import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/theme.dart';
import '../../providers/saved_addresses_provider.dart';
import '../../models/saved_address_model.dart';

class SelectAddressOnMapScreen extends StatefulWidget {
  final SavedAddress? addressToEdit;

  const SelectAddressOnMapScreen({
    super.key,
    this.addressToEdit,
  });

  @override
  State<SelectAddressOnMapScreen> createState() => _SelectAddressOnMapScreenState();
}

class _SelectAddressOnMapScreenState extends State<SelectAddressOnMapScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(31.7683, 35.2137); // Jerusalem default
  String _selectedAddress = 'Select location on map';
  String _labelInput = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _selectedLocation = LatLng(
        widget.addressToEdit!.latitude,
        widget.addressToEdit!.longitude,
      );
      _selectedAddress = widget.addressToEdit!.address;
      _labelInput = widget.addressToEdit!.label;
      _getAddressFromCoordinates(_selectedLocation);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = '${location.latitude}, ${location.longitude}';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromCoordinates(location);
  }

  void _saveAddress() {
    if (_labelInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label (Home, Office, etc.)')),
      );
      return;
    }

    final provider = Provider.of<SavedAddressesProvider>(context, listen: false);

    if (widget.addressToEdit != null) {
      provider.updateAddress(
        id: widget.addressToEdit!.id,
        label: _labelInput,
        address: _selectedAddress,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated')),
      );
    } else {
      provider.addAddress(
        label: _labelInput,
        address: _selectedAddress,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addressToEdit != null ? 'Edit Address' : 'Add Address'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                infoWindow: InfoWindow(
                  title: _labelInput.isEmpty ? 'New Location' : _labelInput,
                  snippet: _selectedAddress,
                ),
              ),
            },
          ),

          // Center pin indicator
          Center(
            child: Positioned(
              child: Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),

          // Bottom sheet with address info and label input
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address display
                    const Text(
                      'Selected Address',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingAddress
                                ? const Text(
                                    'Loading address...',
                                    style: TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 13,
                                    ),
                                  )
                                : Text(
                                    _selectedAddress,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Label input
                    const Text(
                      'Label (Home, Office, Gym, etc.)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: _labelInput),
                      onChanged: (value) => setState(() => _labelInput = value),
                      decoration: InputDecoration(
                        hintText: 'e.g., Home',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        child: Text(
                          widget.addressToEdit != null ? 'Update Address' : 'Save Address',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
