import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/location_provider.dart';
import '../providers/ride_provider.dart';
import 'package:provider/provider.dart';

class RideSelectionBottomSheet extends StatefulWidget {
  final double? distanceKm;
  final double? durationMinutes;
  
  const RideSelectionBottomSheet({
    super.key,
    this.distanceKm,
    this.durationMinutes,
  });

  @override
  State<RideSelectionBottomSheet> createState() => _RideSelectionBottomSheetState();
}

class _RideSelectionBottomSheetState extends State<RideSelectionBottomSheet> {
  String _selectedRideType = 'wassel';
  String _selectedPaymentMethod = 'cash'; // cash, google_pay, credit_card
  
  /// Calculate estimated fare based on route data
  String _calculateEstimatedFare() {
    if (widget.distanceKm == null || widget.durationMinutes == null) {
      return '₪45'; // Fallback estimate
    }
    
    final estimate = FareConstants.calculateEstimatedFare(
      distanceKm: widget.distanceKm!,
      timeMinutes: widget.durationMinutes!,
    );
    
    return '₪${estimate.toStringAsFixed(0)}';
  }
  
  /// Get price range for display
  Map<String, double> _getPriceRange() {
    if (widget.distanceKm == null || widget.durationMinutes == null) {
      return {'min': 40, 'max': 50, 'estimate': 45};
    }
    
    return FareConstants.calculatePriceRange(
      distanceKm: widget.distanceKm!,
      timeMinutes: widget.durationMinutes!,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.85,
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
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Scrollable car options only
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Ride Options
                        _buildRideOptions(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  
                  // Fixed bottom section (payment + button)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: const Border(
                        top: BorderSide(color: AppColors.divider, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Payment method
                        _buildPaymentMethod(),
                        
                        const SizedBox(height: 12),
                        
                        // Fixed Bottom Button
                        _buildFixedButton(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  
  Widget _buildFixedButton() {
    String buttonText;
    switch (_selectedRideType) {
      case 'wassel':
        buttonText = 'Select Wassel';
        break;
      case 'economy':
        buttonText = 'Select Economy';
        break;
      case 'xl':
        buttonText = 'Select XL';
        break;
      case 'express':
        buttonText = 'Select Express';
        break;
      case 'comfort':
        buttonText = 'Select Comfort';
        break;
      default:
        buttonText = 'Select Ride';
    }
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Set up ride provider with selected ride type
              final rideProvider = Provider.of<RideProvider>(context, listen: false);
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              
              // Find and select the ride type
              final selectedType = rideProvider.availableRideTypes.firstWhere(
                (type) => type.id == _selectedRideType,
                orElse: () => rideProvider.availableRideTypes[0],
              );
              rideProvider.selectRideType(selectedType);
              
              // Calculate and set the fare from this screen
              if (widget.distanceKm != null && widget.durationMinutes != null) {
                final fare = FareConstants.calculateEstimatedFare(
                  distanceKm: widget.distanceKm!,
                  timeMinutes: widget.durationMinutes!,
                );
                rideProvider.setEstimatedFare(fare);
              }
              
              // Set locations if available
              if (locationProvider.pickupLocation != null && locationProvider.dropoffLocation != null) {
                rideProvider.setLocations(
                  LatLng(
                    locationProvider.pickupLocation!.latitude,
                    locationProvider.pickupLocation!.longitude,
                  ),
                  LatLng(
                    locationProvider.dropoffLocation!.latitude,
                    locationProvider.dropoffLocation!.longitude,
                  ),
                );
              }
              
              // Navigate to driver search
              Navigator.pushNamed(context, AppRouter.driverSearch);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Purple
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Schedule button
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: IconButton(
            icon: const Icon(Icons.schedule, color: AppColors.textDark, size: 22),
            onPressed: () {
              // Schedule ride for later
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Schedule Ride'),
                    content: const Text('Choose when you want to be picked up.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Show date/time picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ride scheduled!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Schedule'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildRouteInfoUnused(LocationProvider locationProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Pickup
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759), // Green
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  locationProvider.pickupLocation?.address ?? 'Pickup location',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
          
          // Connecting line
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: AppColors.divider,
                ),
              ],
            ),
          ),
          
          // Destination
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), // Blue
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  locationProvider.dropoffLocation?.address ?? 'Destination',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.locationSearch);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, thickness: 1),
          
          // Add a stop
          GestureDetector(
            onTap: () {
              // Add stop functionality
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textMedium, width: 2),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add a stop',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRideOptions() {
    // Get calculated fare based on actual route
    final estimatedFare = _calculateEstimatedFare();
    final durationText = widget.durationMinutes != null 
        ? '${widget.durationMinutes!.toStringAsFixed(0)} min'
        : '4 min';
    
    return Column(
      children: [
        _buildRideOption(
          type: 'wassel',
          imagePath: 'assets/images/cars/wassel.png',
          title: 'Wassel',
          subtitle: durationText,
          passengers: 4,
          price: estimatedFare,
          showRecommended: true,
          isSelected: _selectedRideType == 'wassel',
        ),
        const SizedBox(height: 8),
        _buildRideOption(
          type: 'economy',
          imagePath: 'assets/images/cars/economy.png',
          title: 'Economy',
          subtitle: durationText,
          passengers: 3,
          price: estimatedFare,
          description: 'Affordable rides',
          isSelected: _selectedRideType == 'economy',
        ),
        const SizedBox(height: 8),
        _buildRideOption(
          type: 'xl',
          imagePath: 'assets/images/cars/xl.png',
          title: 'XL',
          subtitle: durationText,
          passengers: 6,
          price: estimatedFare,
          isSelected: _selectedRideType == 'xl',
        ),
        const SizedBox(height: 8),
        _buildRideOption(
          type: 'express',
          imagePath: 'assets/images/cars/express.png',
          title: 'Express',
          subtitle: durationText,
          passengers: 4,
          price: estimatedFare,
          description: 'Faster arrival',
          isSelected: _selectedRideType == 'express',
        ),
        const SizedBox(height: 8),
        _buildRideOption(
          type: 'comfort',
          imagePath: 'assets/images/cars/comfort.png',
          title: 'Comfort',
          subtitle: durationText,
          passengers: 4,
          price: estimatedFare,
          description: 'Extra legroom',
          isSelected: _selectedRideType == 'comfort',
        ),
      ],
    );
  }
  
  Widget _buildRideOption({
    required String type,
    required String imagePath,
    required String title,
    required String subtitle,
    required int passengers,
    required String price,
    String? description,
    bool showRecommended = false,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Car image
            SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textMedium),
                      Text(
                        passengers.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  if (showRecommended) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Price on the right with discount - clickable for breakdown
            GestureDetector(
              onTap: () {
                _showFareBreakdown(price);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Original price (struck through)
                  Text(
                    _getOriginalPrice(price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Discounted price (the actual price shown in dark)
                  Text(
                    _calculateDiscountedPrice(price),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Savings text (gray, not purple)
                  Text(
                    _calculateSavings(price),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildByTheMeterUnused() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'By the meter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.textMedium),
                    SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Earn 20 Wassel points in this ride',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoteToDriverUnused() {
    return GestureDetector(
      onTap: () {
        // Show note dialog
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.note_outlined, color: AppColors.textMedium),
            SizedBox(width: 12),
            Text(
              'Note to driver',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textMedium),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethod() {
    return GestureDetector(
      onTap: () {
        _showPaymentOptions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: _getPaymentIconWidget(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPaymentLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textMedium, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _getPaymentIconWidget() {
    switch (_selectedPaymentMethod) {
      case 'google_pay':
        return const Icon(Icons.payment, color: AppColors.textDark, size: 18);
      case 'credit_card':
        return const Icon(Icons.credit_card, color: AppColors.textDark, size: 18);
      case 'cash':
      default:
        return Image.asset('assets/images/cash.png', width: 18, height: 18);
    }
  }
  
  String _getPaymentLabel() {
    switch (_selectedPaymentMethod) {
      case 'google_pay':
        return 'Google Pay';
      case 'credit_card':
        return 'Credit Card';
      case 'cash':
      default:
        return 'Cash';
    }
  }
  
  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentOptionWithImage(
                imagePath: 'assets/images/cash.png',
                title: 'Cash',
                subtitle: 'Pay with cash',
                value: 'cash',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                icon: Icons.payment,
                title: 'Google Pay',
                subtitle: 'Quick and secure',
                value: 'google_pay',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                icon: Icons.credit_card,
                title: 'Credit Card',
                subtitle: 'Add card details',
                value: 'credit_card',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
        Navigator.pop(context);
        
        // If credit card selected, show add card dialog
        if (value == 'credit_card') {
          _showAddCreditCardDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentOptionWithImage({
    required String imagePath,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
  
  void _showAddCreditCardDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Credit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save card details
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card added successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add Card'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildOrderButtonUnused() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to active ride screen
        Navigator.pushNamed(context, AppRouter.activeRide);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9500), // Orange color like Gett
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Order Now',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _calculateDiscountedPrice(String priceStr) {
    // This IS the discounted price (shown in purple)
    // The original price shown struck through is 5% higher
    return priceStr; // Return the price as-is (this is the discount)
  }
  
  String _calculateSavings(String priceStr) {
    // Extract number from price string
    final priceNum = double.tryParse(priceStr.replaceAll('₪', '').trim()) ?? 0;
    
    // Calculate 10% Wassel fee
    final markup = priceNum * 0.10;
    
    return 'Save ₪${markup.toStringAsFixed(0)}';
  }
  
  String _getOriginalPrice(String priceStr) {
    // Extract number from price string
    final priceNum = double.tryParse(priceStr.replaceAll('₪', '').trim()) ?? 0;
    
    // Original price is 10% higher (Wassel fee)
    final originalPrice = priceNum * 1.10;
    
    return '₪${originalPrice.toStringAsFixed(0)}';
  }
  
  void _showFareBreakdown(String price) {
    final priceNum = double.tryParse(price.replaceAll('₪', '').trim()) ?? 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FareBreakdownSheet(
          priceNum: priceNum,
          zone: 'ISRAEL', // TODO: Detect zone based on location
        );
      },
    );
  }
}

// Fare calculation constants (VAT-inclusive, effective April 1, 2025)
// Based on Legal Decree 11807 - Final prices for Israel launch cities
class FareConstants {
  // Israel Zone (Jerusalem, Haifa, Tel Aviv, etc.)
  static const double startFee = 12.82;
  static const double tariffA = 2.01; // Day rate (per km OR per min)
  static const double tariffB = 2.40; // Night rate
  static const double tariffC = 2.81; // Late night rate
  static const double driverDispatchFee = 5.92;
  
  // Other Fees
  static const double cancellationFee = 5.92;
  static const double waitTimeFee = 2.01;
  
  // Legal Surcharges (Pass-through to driver)
  static const double road6Fee = 19.48;
  static const double road6Sec18Fee = 7.48;
  static const double carmelTunnel1Fee = 11.59;
  static const double carmelTunnel2Fee = 23.18;
  static const double bgnAirportFee = 5.00;
  static const double otherAirportFee = 2.00;
  
  // Commission (Launch Promo)
  static const double wasselCommissionRate = 0.00; // 0% for launch
  
  /// Calculate estimated fare based on distance and time
  /// The meter uses EITHER distance OR time rate, never both simultaneously
  /// We estimate using the higher of the two for accuracy
  static double calculateEstimatedFare({
    required double distanceKm,
    required double timeMinutes,
    double surcharges = 0.0,
  }) {
    // Calculate both distance-based and time-based fares
    final distanceFare = distanceKm * tariffA;
    final timeFare = timeMinutes * tariffA;
    
    // Use the higher value (meter switches automatically)
    final meterFare = distanceFare > timeFare ? distanceFare : timeFare;
    
    // Total = Start Fee + Meter Fare + Driver Dispatch Fee + Surcharges
    final total = startFee + meterFare + driverDispatchFee + surcharges;
    
    return total;
  }
  
  /// Calculate price range (min to max estimate)
  static Map<String, double> calculatePriceRange({
    required double distanceKm,
    required double timeMinutes,
    double surcharges = 0.0,
  }) {
    final baseEstimate = calculateEstimatedFare(
      distanceKm: distanceKm,
      timeMinutes: timeMinutes,
      surcharges: surcharges,
    );
    
    // Add ±10% for traffic/route variations
    final minPrice = baseEstimate * 0.9;
    final maxPrice = baseEstimate * 1.1;
    
    return {
      'min': minPrice,
      'max': maxPrice,
      'estimate': baseEstimate,
    };
  }
  
  // Calculate final prices (for completed rides)
  static double calculateTotalPassengerPrice(
    double finalMeterFare,
    double otherSurcharges,
  ) {
    return finalMeterFare + driverDispatchFee + otherSurcharges;
  }
  
  static double calculateWasselRevenue(double finalMeterFare) {
    return finalMeterFare * wasselCommissionRate; // ₪0.00 during launch
  }
  
  static double calculateDriverPayout(
    double finalMeterFare,
    double otherSurcharges,
  ) {
    return (finalMeterFare * (1 - wasselCommissionRate)) +
        driverDispatchFee +
        otherSurcharges;
  }
}

class _FareBreakdownSheet extends StatefulWidget {
  final double priceNum;
  final String zone;
  
  const _FareBreakdownSheet({
    required this.priceNum,
    required this.zone,
  });
  
  @override
  State<_FareBreakdownSheet> createState() => _FareBreakdownSheetState();
}

class _FareBreakdownSheetState extends State<_FareBreakdownSheet> {
  bool showDetails = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'How Your Fare is Calculated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppColors.textMedium),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Fare amount with expand/collapse
            GestureDetector(
              onTap: () {
                setState(() {
                  showDetails = !showDetails;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fare',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₪${widget.priceNum.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        showDetails ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textMedium,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Meter Start Fee
              _buildFareItemWithDescription(
                title: 'Meter Start Fee',
                amount: '₪${FareConstants.startFee.toStringAsFixed(2)}',
                description: 'The legal start price for all taxis',
              ),
              const SizedBox(height: 12),
              
              // Distance Rate
              _buildFareItemWithDots(
                title: 'Distance Rate (Tariff A)',
                amount: '₪${FareConstants.tariffA.toStringAsFixed(2)} / km',
              ),
              const SizedBox(height: 8),
              
              // Time Rate
              _buildFareItemWithDots(
                title: 'Time Rate (Tariff A)',
                amount: '₪${FareConstants.tariffA.toStringAsFixed(2)} / min',
              ),
              const SizedBox(height: 12),
              
              // Info box about meter switching
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your meter automatically switches between the Time and Distance rate based on traffic. It never charges both at the same time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Driver Dispatch Fee
              _buildFareItemWithDescription(
                title: 'Driver Dispatch Fee',
                amount: '₪${FareConstants.driverDispatchFee.toStringAsFixed(2)}',
                description: 'The driver\'s standard fee for app-booked service',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Other Fees Header
              const Text(
                'OTHER FEES (if applicable)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Cancellation Fee
            _buildFareItemWithDots(
              title: 'Cancellation Fee',
              amount: '₪${FareConstants.cancellationFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            
            // Wait Time Fee
            _buildFareItemWithDots(
              title: 'Wait Time Fee',
              amount: '₪${FareConstants.waitTimeFee.toStringAsFixed(2)} / min',
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Launch Promo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'LAUNCH PROMO: 0% COMMISSION',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '100% of your total fare (including the Driver Dispatch Fee) goes directly to your driver.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Got it button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFareItemWithDots({
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dotWidth = 4.0;
                final dotSpacing = 4.0;
                final dotsCount = ((constraints.maxWidth) / (dotWidth + dotSpacing)).toInt();
                
                return Row(
                  children: List.generate(
                    dotsCount,
                    (index) => Container(
                      width: dotWidth,
                      height: 1,
                      margin: EdgeInsets.symmetric(horizontal: dotSpacing / 2),
                      color: AppColors.divider,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFareItemWithDescription({
    required String title,
    required String amount,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}
