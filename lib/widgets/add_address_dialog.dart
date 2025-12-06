import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/saved_address_model.dart';
import '../providers/saved_addresses_provider.dart';

class AddAddressDialog extends StatefulWidget {
  final SavedAddress? addressToEdit;

  const AddAddressDialog({
    super.key,
    this.addressToEdit,
  });

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  String? _selectedLabel;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _labelController = TextEditingController(text: widget.addressToEdit!.label);
      _addressController = TextEditingController(text: widget.addressToEdit!.address);
      _latitudeController = TextEditingController(text: widget.addressToEdit!.latitude.toString());
      _longitudeController = TextEditingController(text: widget.addressToEdit!.longitude.toString());
    } else {
      _labelController = TextEditingController();
      _addressController = TextEditingController();
      _latitudeController = TextEditingController();
      _longitudeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.addressToEdit != null ? 'Edit Address' : 'Add Address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label dropdown
            Consumer<SavedAddressesProvider>(
              builder: (context, provider, child) {
                final commonLabels = provider.getCommonLabels();
                return DropdownButtonFormField<String>(
                  value: _selectedLabel,
                  hint: const Text('Select or type label'),
                  items: commonLabels.map((label) {
                    return DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLabel = value;
                      _labelController.text = value ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Label (Home, Office, etc.)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Custom label input
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Custom Label',
                hintText: 'e.g., Mom\'s House',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Address input
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Full address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Latitude
            TextField(
              controller: _latitudeController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: '31.7683',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Longitude
            TextField(
              controller: _longitudeController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: '35.2137',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAddress,
          child: Text(widget.addressToEdit != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveAddress() {
    if (_labelController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final latitude = double.parse(_latitudeController.text);
      final longitude = double.parse(_longitudeController.text);

      final provider = Provider.of<SavedAddressesProvider>(context, listen: false);

      if (widget.addressToEdit != null) {
        provider.updateAddress(
          id: widget.addressToEdit!.id,
          label: _labelController.text,
          address: _addressController.text,
          latitude: latitude,
          longitude: longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated')),
        );
      } else {
        provider.addAddress(
          label: _labelController.text,
          address: _addressController.text,
          latitude: latitude,
          longitude: longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address added')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid coordinates: $e')),
      );
    }
  }
}
