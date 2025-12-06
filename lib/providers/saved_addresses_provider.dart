import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_address_model.dart';

class SavedAddressesProvider extends ChangeNotifier {
  final List<SavedAddress> _savedAddresses = [];

  List<SavedAddress> get savedAddresses => _savedAddresses;

  // Get address by label
  SavedAddress? getAddressByLabel(String label) {
    try {
      return _savedAddresses.firstWhere((addr) => addr.label.toLowerCase() == label.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Add new saved address
  void addAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final newAddress = SavedAddress(
      id: const Uuid().v4(),
      label: label,
      address: address,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );
    _savedAddresses.add(newAddress);
    notifyListeners();
    print('✅ Added saved address: $label');
  }

  // Update saved address
  void updateAddress({
    required String id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final index = _savedAddresses.indexWhere((addr) => addr.id == id);
    if (index != -1) {
      _savedAddresses[index] = _savedAddresses[index].copyWith(
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
      print('✅ Updated saved address: $label');
    }
  }

  // Delete saved address
  void deleteAddress(String id) {
    _savedAddresses.removeWhere((addr) => addr.id == id);
    notifyListeners();
    print('✅ Deleted saved address');
  }

  // Check if address label already exists
  bool addressLabelExists(String label) {
    return _savedAddresses.any((addr) => addr.label.toLowerCase() == label.toLowerCase());
  }

  // Get common labels
  List<String> getCommonLabels() {
    return ['Home', 'Office', 'Gym', 'School', 'Hospital', 'Airport'];
  }
}
