import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../screens/home/location_search_screen.dart';
import '../screens/ride/driver_search_screen.dart';
import '../screens/ride/driver_selection_screen.dart';
import '../screens/ride/active_ride_screen.dart';
import '../screens/ride/driver_arrived_screen.dart';
import '../screens/ride/onboard_confirmation_screen.dart';
import '../screens/ride/en_route_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/account/my_account_screen.dart';
import '../screens/account/saved_addresses_screen.dart';
import '../screens/account/select_address_on_map_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/invite/invite_friends_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String phoneVerification = '/phone-verification';
  static const String home = '/home';
  static const String locationSearch = '/location-search';
  static const String rideSelection = '/ride-selection';
  static const String driverSearch = '/driver-search';
  static const String driverSelection = '/driver-selection';
  static const String activeRide = '/active-ride';
  static const String driverArrived = '/driver-arrived';
  static const String onboardConfirmation = '/onboard-confirmation';
  static const String enRoute = '/en-route';
  static const String profile = '/profile';
  static const String myAccount = '/my-account';
  static const String wallet = '/wallet';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String inviteFriends = '/invite-friends';
  static const String subscription = '/subscription';
  static const String appSettings = '/settings';
  static const String support = '/support';
  static const String savedAddresses = '/saved-addresses';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      
      case phoneVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );
      
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        final tabIndex = args?['tabIndex'] as int?;
        return MaterialPageRoute(
          builder: (_) => MainNavigationScreen(initialTabIndex: tabIndex),
        );
      
      case locationSearch:
        return MaterialPageRoute(builder: (_) => const LocationSearchScreen());
      
      case driverSearch:
        return MaterialPageRoute(builder: (_) => const DriverSearchScreen());
      
      case driverSelection:
        return MaterialPageRoute(builder: (_) => const DriverSelectionScreen());
      
      case activeRide:
        return MaterialPageRoute(builder: (_) => const ActiveRideScreen());
      
      case driverArrived:
        return MaterialPageRoute(builder: (_) => const DriverArrivedScreen());
      
      case onboardConfirmation:
        return MaterialPageRoute(builder: (_) => const OnboardConfirmationScreen());
      
      case enRoute:
        return MaterialPageRoute(builder: (_) => const EnRouteScreen());
      
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case myAccount:
        return MaterialPageRoute(builder: (_) => const MyAccountScreen());
      
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      
      case inviteFriends:
        return MaterialPageRoute(builder: (_) => const InviteFriendsScreen());
      
      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      
      case appSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      
      case savedAddresses:
        return MaterialPageRoute(builder: (_) => const SavedAddressesScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
