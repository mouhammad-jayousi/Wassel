import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85, // 85% width
      child: Column(
        children: [
          // Gradient Header with Profile - NO rounded corners, full gradient
          _buildGradientHeader(context),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'My Account',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Account tab (index 2) in MainNavigationScreen
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.home,
                      arguments: {'tabIndex': 2},
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.wallet);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: 'My Rides',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Rides tab (index 1) in MainNavigationScreen
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.home,
                      arguments: {'tabIndex': 1},
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.savedAddresses);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.notifications);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.card_giftcard_outlined,
                  title: 'Invite Friends',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.inviteFriends);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.star_outline,
                  title: 'Subscription',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.subscription);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.appSettings);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Contact & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.support);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    // Mock user data
    const userName = 'MJ';
    const userPoints = 2500;
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,           // Black at top
            Color(0xFFDA015C),      // Primary pink at bottom
          ],
        ),
        // NO borderRadius - full gradient to edges
      ),
      child: SafeArea(
        bottom: false, // Don't add bottom padding
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Photo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.white,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // User Name
              const Text(
                userName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '$userPoints',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMedium,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textDark,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
