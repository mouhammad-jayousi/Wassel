# Wassel Rider App - Technical Documentation
## Based on Current Codebase (As-Is)

**Version:** 1.0.0+1  
**Last Updated:** January 28, 2026  
**Status:** Prototype/Development

> **Note:** This documentation reflects ONLY what currently exists in the codebase, not planned features.

---

## Table of Contents

1. [What We Actually Have](#what-we-actually-have)
2. [Project Structure](#project-structure)
3. [Technology Stack](#technology-stack)
4. [State Management (Providers)](#state-management-providers)
5. [Services Layer](#services-layer)
6. [Screens (UI)](#screens-ui)
7. [Widgets (Reusable Components)](#widgets-reusable-components)
8. [Theme & Styling](#theme--styling)
9. [Navigation & Routes](#navigation--routes)
10. [Firebase Configuration](#firebase-configuration)
11. [Google Maps Setup](#google-maps-setup)
12. [Dependencies](#dependencies)
13. [Assets](#assets)
14. [How to Run](#how-to-run)

---

## What We Actually Have

### ✅ Implemented (Exists in Code)

**State Management:**
- ✅ 4 Providers (Auth, Location, Ride, SavedAddresses)
- ✅ Provider pattern with ChangeNotifier

**Services:**
- ✅ FirebaseAuthService (Phone authentication)
- ✅ FirestoreService (Database operations - methods defined)
- ✅ GeocodingService (Google Geocoding API)
- ✅ FirebaseMessagingService (Push notifications setup)

**Screens:**
- ✅ 25 UI screens (all implemented)
- ✅ Complete authentication flow
- ✅ Home screen with Google Maps
- ✅ Ride booking flow UI
- ✅ Profile and account management

**UI Components:**
- ✅ 7 custom widgets
- ✅ Custom theme with pink/magenta color scheme
- ✅ Material Design 3

**Integrations:**
- ✅ Firebase (Auth, Firestore, Messaging, Storage, Analytics, Crashlytics)
- ✅ Google Maps (Maps SDK, Directions, Places, Geocoding)
- ✅ Phone authentication with OTP

### ❌ NOT Implemented (Does Not Exist)

- ❌ Payment gateway integration
- ❌ Real backend API (using mock data in providers)
- ❌ WebSocket/Real-time tracking
- ❌ Driver app
- ❌ Admin panel
- ❌ Actual ride matching algorithm
- ❌ Live driver location updates
- ❌ In-app messaging/chat
- ❌ Receipt generation
- ❌ Promo code backend logic

---

## Project Structure

### Actual File Tree

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase config (auto-generated)
│
├── config/                            # Configuration
│   ├── theme.dart                     # AppColors & AppTheme
│   └── routes.dart                    # AppRouter with 24 routes
│
├── models/                            # Data Models
│   └── saved_address_model.dart       # SavedAddressModel class
│
├── providers/                         # State Management (4 files)
│   ├── auth_provider.dart             # Authentication state
│   ├── location_provider.dart         # Location & GPS state
│   ├── ride_provider.dart             # Ride booking state (mock data)
│   └── saved_addresses_provider.dart  # Saved places state
│
├── services/                          # Business Logic (4 files)
│   ├── firebase_auth_service.dart     # Firebase phone auth
│   ├── firebase_messaging_service.dart# FCM push notifications
│   ├── firestore_service.dart         # Firestore CRUD methods
│   └── geocoding_service.dart         # Google Geocoding API
│
├── screens/                           # UI Screens (25 files)
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── auth/
│   │   ├── sign_in_screen.dart
│   │   ├── sign_up_screen.dart
│   │   └── phone_verification_screen.dart
│   ├── main/
│   │   └── main_navigation_screen.dart  # Bottom nav with 3 tabs
│   ├── home/
│   │   ├── home_screen.dart             # Map + ride booking
│   │   └── location_search_screen.dart  # Search places
│   ├── ride/
│   │   ├── driver_search_screen.dart
│   │   ├── driver_selection_screen.dart
│   │   ├── active_ride_screen.dart
│   │   ├── driver_arrived_screen.dart
│   │   ├── en_route_screen.dart
│   │   └── onboard_confirmation_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── account/
│   │   ├── my_account_screen.dart
│   │   ├── saved_addresses_screen.dart
│   │   └── select_address_on_map_screen.dart
│   ├── history/
│   │   └── history_screen.dart
│   ├── wallet/
│   │   └── wallet_screen.dart           # UI only, no payment
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── support/
│   │   └── support_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   ├── subscription/
│   │   └── subscription_screen.dart     # UI only
│   └── invite/
│       └── invite_friends_screen.dart
│
└── widgets/                           # Reusable Components (7 files)
    ├── add_address_dialog.dart        # Dialog for adding addresses
    ├── app_drawer.dart                # Navigation drawer
    ├── custom_button.dart             # Custom button widget
    ├── custom_text_field.dart         # Custom input field
    ├── loading_indicator.dart         # Loading spinner
    ├── map_widget.dart                # Google Maps wrapper
    └── ride_selection_bottom_sheet.dart # Vehicle selection sheet
```

**Total Files:**
- 45 Dart files
- 4 Providers
- 4 Services
- 25 Screens
- 7 Widgets
- 2 Config files
- 1 Model
- 1 Main file
- 1 Firebase options file

---

## Technology Stack

### Framework & Language

```yaml
Flutter SDK: >=3.0.0 <4.0.0
Dart SDK: >=3.0.0 <4.0.0
```

### Actual Dependencies (from pubspec.yaml)

**UI & Design:**
```yaml
cupertino_icons: ^1.0.6
google_fonts: ^6.1.0
flutter_svg: ^2.0.9
cached_network_image: ^3.3.0
shimmer: ^3.0.0
lottie: ^2.7.0
flutter_rating_bar: ^4.0.1
smooth_page_indicator: ^1.1.0
```

**State Management:**
```yaml
provider: ^6.1.0
get_it: ^7.6.0
```

**Navigation:**
```yaml
go_router: ^12.0.0
```

**Maps & Location:**
```yaml
google_maps_flutter: ^2.5.0
google_maps_flutter_web: ^0.5.4
geolocator: ^10.1.0
geocoding: ^2.1.1
flutter_polyline_points: ^2.0.0
```

**HTTP & API:**
```yaml
dio: ^5.4.0
pretty_dio_logger: ^1.3.1
http: ^1.1.0
```

**Storage:**
```yaml
shared_preferences: ^2.2.2
```

**Utils:**
```yaml
intl: ^0.18.1
uuid: ^4.2.1
equatable: ^2.0.5
permission_handler: ^11.0.1
image_picker: ^1.0.5
country_picker: ^2.0.20
webview_flutter: ^4.4.2
```

**Firebase:**
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_messaging: ^14.7.9
firebase_storage: ^11.5.6
firebase_crashlytics: ^3.4.8
firebase_analytics: ^10.7.4
```

**Dev Dependencies:**
```yaml
flutter_test: sdk: flutter
flutter_lints: ^3.0.0
```

---

## State Management (Providers)

### 1. AuthProvider (`providers/auth_provider.dart`)

**Purpose:** Manages authentication state

**State Variables:**
```dart
bool _isAuthenticated = false;
bool _hasSeenOnboarding = false;
String? _userId;
String? _phoneNumber;
String? _userName;
String? _verificationId;
String? _errorMessage;
```

**Public Getters:**
```dart
bool get isAuthenticated
bool get hasSeenOnboarding
String? get userId
String? get phoneNumber
String? get userName
String? get errorMessage
```

**Methods:**
```dart
Future<bool> signInWithPhone(String phoneNumber)
Future<bool> verifyOTP(String otp)
void markOnboardingAsViewed()
Future<void> updateProfile({String? userName, String? email, String? profileImageUrl})
Future<void> signUp({required String email, required String phoneNumber, required String name})
Future<void> logout()
Future<void> deleteAccount()
```

### 2. LocationProvider (`providers/location_provider.dart`)

**Purpose:** Manages location and address state

**Data Model:**
```dart
class LocationModel {
  final String address;
  final double latitude;
  final double longitude;
}
```

**State Variables:**
```dart
LocationModel? _currentLocation;
LocationModel? _pickupLocation;
LocationModel? _dropoffLocation;
List<LocationModel> _stops = [];
List<LocationModel> _recentLocations = [];
List<LocationModel> _savedPlaces = [];
```

**Methods:**
```dart
Future<void> getCurrentLocation()
void setPickupLocation(LocationModel location)
void setDropoffLocation(LocationModel? location)
void clearDropoffLocation()
void addStop(LocationModel stop)
void updateStop(int index, LocationModel stop)
void removeStop(int index)
void clearStops()
void addSavedPlace(LocationModel location)
void removeSavedPlace(LocationModel location)
Future<void> updatePickupFromCoordinates(double latitude, double longitude, {String? address})
Future<void> updateDropoffFromCoordinates(double latitude, double longitude, {String? address})
```

### 3. RideProvider (`providers/ride_provider.dart`)

**Purpose:** Manages ride booking state (USES MOCK DATA)

**Enums:**
```dart
enum RideStatus {
  idle,
  searching,
  driverAvailable,
  driverConfirmed,
  driverArriving,
  driverArrived,
  rideStarted,
  rideCompleted,
  cancelled,
}
```

**Data Models:**
```dart
class RideType {
  final String id;
  final String name;
  final String icon;
  final double pricePerKm;
  final String estimatedPrice;
}

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String photo;
  final double rating;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;
  final double distanceKm;
  final int etaMinutes;
  final LatLng currentLocation;
}
```

**State Variables:**
```dart
RideStatus _status = RideStatus.idle;
RideType? _selectedRideType;
DriverModel? _assignedDriver;
List<DriverModel> _availableDrivers = [];
int _currentDriverIndex = 0;
double _estimatedFare = 0.0;
String? _promoCode;
double _discount = 0.0;
LatLng? _pickupLocation;
LatLng? _dropoffLocation;
String? _pickupAddress;
String? _dropoffAddress;
```

**Methods:**
```dart
void setLocations(LatLng pickup, LatLng dropoff, {String? pickupAddr, String? dropoffAddr})
void selectRideType(RideType rideType)
void setEstimatedFare(double fare)
Future<void> requestRide(String userId)  // MOCK: Creates fake drivers
void nextDriver()
void previousDriver()
Future<void> confirmDriver()
void applyPromoCode(String code)  // MOCK: Hardcoded $5 discount
Future<void> cancelRide(String userId)
void startRide()
Future<void> completeRide()
void resetRide()
```

**⚠️ Important:** This provider uses MOCK data. The `requestRide()` method creates fake drivers after a 2-second delay.

### 4. SavedAddressesProvider (`providers/saved_addresses_provider.dart`)

**Purpose:** Manages saved addresses

**Methods:**
```dart
Future<void> loadAddresses(String userId)
Future<void> addAddress(String userId, SavedAddressModel address)
Future<void> updateAddress(String userId, SavedAddressModel address)
Future<void> deleteAddress(String userId, String addressId)
```

---

## Services Layer

### 1. FirebaseAuthService (`services/firebase_auth_service.dart`)

**Purpose:** Firebase phone authentication

**Dependencies:**
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
```

**Key Methods:**
```dart
Future<bool> sendOTP({
  required String phoneNumber,
  required Function(String verificationId) onCodeSent,
  required Function(String error) onError,
})

Future<UserCredential?> verifyOTP({
  required String otp,
  String? verificationId,
})

Future<void> updateUserProfile({
  required String userId,
  String? userName,
  String? email,
  String? profileImageUrl,
})

Future<Map<String, dynamic>?> getUserData(String userId)

Future<void> signOut()

Future<void> deleteAccount()
```

**Firestore User Document Structure:**
```dart
{
  'uid': user.uid,
  'phoneNumber': user.phoneNumber,
  'createdAt': FieldValue.serverTimestamp(),
  'userName': 'MJ',
  'rating': 5.0,
  'totalRides': 0,
  'profileImageUrl': '',
}
```

### 2. GeocodingService (`services/geocoding_service.dart`)

**Purpose:** Google Geocoding API integration

**API Key (Hardcoded):**
```dart
static const String _apiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
```

**Endpoints:**
```dart
static const String _geocodeBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';
```

**Methods:**
```dart
static Future<Map<String, dynamic>?> geocodeAddress(String address)
// Returns: {latitude, longitude, address}

static Future<String?> reverseGeocode(double latitude, double longitude)
// Returns: formatted address string

static Future<List<Map<String, dynamic>>> searchPlaces(String query, {String region = 'IL'})
// Returns: List of {name, address, latitude, longitude, types}
```

### 3. FirestoreService (`services/firestore_service.dart`)

**Purpose:** Firestore database operations (METHODS DEFINED, NOT USED)

**Collections:**
- `rides/` - Ride documents
- `drivers/` - Driver documents
- `messages/` - Chat messages
- `favorites/` - Saved locations

**Methods (Defined but not actively used):**
```dart
// Ride Management
Future<String> createRide({...})
Future<void> updateRideStatus(String rideId, String status)
Future<void> assignDriverToRide(String rideId, String driverId)
Future<void> completeRide(String rideId, double actualFare)
Future<void> cancelRide(String rideId, String cancelledBy)
Future<void> rateRide(String rideId, double rating, String? review)

// Real-time
Future<Map<String, dynamic>?> getRide(String rideId)
Stream<DocumentSnapshot> streamRide(String rideId)
Future<List<Map<String, dynamic>>> getRideHistory(String userId)

// Drivers
Future<List<Map<String, dynamic>>> getNearbyDrivers({...})
Stream<DocumentSnapshot> streamDriverLocation(String driverId)

// Messaging
Future<void> sendMessage({...})
Stream<QuerySnapshot> streamMessages(String rideId)
Future<void> markMessagesAsRead(String rideId, String userId)

// Favorites
Future<void> addFavoriteLocation({...})
Future<List<Map<String, dynamic>>> getFavoriteLocations(String userId)
Future<void> deleteFavoriteLocation(String userId, String favoriteId)
```

**⚠️ Important:** These methods are defined but the app currently uses mock data from RideProvider instead.

### 4. FirebaseMessagingService (`services/firebase_messaging_service.dart`)

**Purpose:** Push notification setup

**Methods:**
```dart
Future<void> initialize()
Future<String?> getToken()
void handleMessage(RemoteMessage message)
```

---

## Screens (UI)

### Complete Screen List (25 screens)

| Screen File | Route | Purpose | Status |
|------------|-------|---------|--------|
| `splash_screen.dart` | `/` | App loading | ✅ Complete |
| `onboarding_screen.dart` | `/onboarding` | First-time intro | ✅ Complete |
| `sign_in_screen.dart` | `/sign-in` | Phone login | ✅ Complete |
| `sign_up_screen.dart` | `/sign-up` | Registration | ✅ Complete |
| `phone_verification_screen.dart` | `/phone-verification` | OTP entry | ✅ Complete |
| `main_navigation_screen.dart` | `/home` | Bottom nav (3 tabs) | ✅ Complete |
| `home_screen.dart` | Tab 0 | Map + booking | ✅ Complete |
| `location_search_screen.dart` | `/location-search` | Search places | ✅ Complete |
| `driver_search_screen.dart` | `/driver-search` | Finding drivers | ✅ Complete |
| `driver_selection_screen.dart` | `/driver-selection` | Choose driver | ✅ Complete |
| `active_ride_screen.dart` | `/active-ride` | Ride tracking | ✅ Complete |
| `driver_arrived_screen.dart` | `/driver-arrived` | Driver waiting | ✅ Complete |
| `onboard_confirmation_screen.dart` | `/onboard-confirmation` | Boarding | ✅ Complete |
| `en_route_screen.dart` | `/en-route` | Trip progress | ✅ Complete |
| `history_screen.dart` | Tab 1 | Past rides | ✅ Complete |
| `profile_screen.dart` | Tab 2 | User profile | ✅ Complete |
| `my_account_screen.dart` | `/my-account` | Edit profile | ✅ Complete |
| `saved_addresses_screen.dart` | `/saved-addresses` | Manage addresses | ✅ Complete |
| `select_address_on_map_screen.dart` | (embedded) | Map picker | ✅ Complete |
| `wallet_screen.dart` | `/wallet` | Payment (UI only) | 🚧 No backend |
| `settings_screen.dart` | `/settings` | App settings | ✅ Complete |
| `support_screen.dart` | `/support` | Help | ✅ Complete |
| `notifications_screen.dart` | `/notifications` | Notifications | ✅ Complete |
| `subscription_screen.dart` | `/subscription` | Premium (UI only) | 🚧 No backend |
| `invite_friends_screen.dart` | `/invite-friends` | Referral | ✅ Complete |

### Main Navigation Structure

**MainNavigationScreen** has 3 tabs:
1. **Home** (Tab 0) - HomeScreen with map
2. **Rides** (Tab 1) - HistoryScreen
3. **Account** (Tab 2) - ProfileScreen

---

## Widgets (Reusable Components)

### 1. CustomButton (`widgets/custom_button.dart`)

**Purpose:** Reusable button with loading state

**Properties:**
```dart
final String text;
final VoidCallback? onPressed;
final bool isLoading;
final bool isOutlined;
final Color? backgroundColor;
final Color? textColor;
final IconData? icon;
final double? width;
final double height;
```

**Usage:**
```dart
CustomButton(
  text: 'Request Ride',
  onPressed: () => _requestRide(),
  isLoading: false,
  backgroundColor: AppColors.primary,
)
```

### 2. CustomTextField (`widgets/custom_text_field.dart`)

**Purpose:** Reusable text input field

**Properties:**
```dart
final String? label;
final String? hint;
final TextEditingController? controller;
final bool obscureText;
final TextInputType? keyboardType;
final Widget? prefixIcon;
final Widget? suffixIcon;
final String? Function(String?)? validator;
final void Function(String)? onChanged;
```

### 3. AppDrawer (`widgets/app_drawer.dart`)

**Purpose:** Navigation drawer menu

**Features:**
- Gradient header (black to pink)
- User profile display
- Points badge
- 9 menu items

**Menu Items:**
1. My Account
2. Payment
3. My Rides
4. Saved Addresses
5. Notifications
6. Invite Friends
7. Subscription
8. Settings
9. Contact & Support

### 4. MapWidget (`widgets/map_widget.dart`)

**Purpose:** Google Maps wrapper

**Features:**
- Displays Google Map
- Handles markers
- Handles polylines
- Camera controls

### 5. RideSelectionBottomSheet (`widgets/ride_selection_bottom_sheet.dart`)

**Purpose:** Vehicle type selection sheet

**Features:**
- Shows available ride types
- Displays estimated fares
- Request ride button
- Promo code input

### 6. LoadingIndicator (`widgets/loading_indicator.dart`)

**Purpose:** Loading spinner

### 7. AddAddressDialog (`widgets/add_address_dialog.dart`)

**Purpose:** Dialog for adding saved addresses

---

## Theme & Styling

### Color Scheme (`config/theme.dart`)

**AppColors Class:**
```dart
// Primary Colors (Pink/Magenta Theme)
static const Color primary = Color(0xFFDA015C);      // Pink/Magenta
static const Color primaryDark = Color(0xFFB00149);
static const Color primaryLight = Color(0xFFFCE4EF);
static const Color black = Color(0xFF000000);

// Accent Colors
static const Color accent = Color(0xFF5B6EF5);       // Blue
static const Color success = Color(0xFF00C853);
static const Color warning = Color(0xFFFFB300);
static const Color error = Color(0xFFF44336);

// Text Colors
static const Color textDark = Color(0xFF2C3E50);
static const Color textMedium = Color(0xFF7F8C8D);
static const Color textLight = Color(0xFFBDC3C7);

// Background Colors
static const Color background = Color(0xFFF5F5F5);
static const Color white = Color(0xFFFFFFFF);
static const Color cardBackground = Color(0xFFFFFFFF);

// Other
static const Color divider = Color(0xFFEEEEEE);
static const Color shadow = Color(0x1A000000);
```

### Typography

**System Fonts:**
- iOS: SF Pro
- Android: Roboto

**Text Styles:**
```dart
displayLarge: 32px, bold
displayMedium: 28px, bold
displaySmall: 24px, semi-bold
headlineMedium: 20px, semi-bold
titleLarge: 18px, semi-bold
titleMedium: 16px, medium
bodyLarge: 16px, regular
bodyMedium: 14px, regular
bodySmall: 12px, regular
```

---

## Navigation & Routes

### AppRouter (`config/routes.dart`)

**All Routes (24 total):**
```dart
static const String splash = '/';
static const String onboarding = '/onboarding';
static const String signIn = '/sign-in';
static const String signUp = '/sign-up';
static const String phoneVerification = '/phone-verification';
static const String home = '/home';
static const String locationSearch = '/location-search';
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
```

**Navigation Method:**
```dart
static Route<dynamic> onGenerateRoute(RouteSettings settings)
```

---

## Firebase Configuration

### Enabled Services

**From `pubspec.yaml`:**
1. ✅ Firebase Core
2. ✅ Firebase Auth (Phone authentication)
3. ✅ Cloud Firestore
4. ✅ Firebase Messaging
5. ✅ Firebase Storage
6. ✅ Firebase Crashlytics
7. ✅ Firebase Analytics

### Initialization (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Messaging
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();
  
  runApp(const WasselApp());
}
```

### Firestore Collections (Defined but not actively used)

```
firestore/
├── users/
│   └── {userId}/
│       ├── uid
│       ├── phoneNumber
│       ├── userName
│       ├── rating
│       ├── totalRides
│       └── createdAt
│
├── rides/ (defined in FirestoreService)
├── drivers/ (defined in FirestoreService)
├── messages/ (defined in FirestoreService)
└── favorites/ (defined in FirestoreService)
```

---

## Google Maps Setup

### API Key (Hardcoded in GeocodingService)

```dart
static const String _apiKey = 'AIzaSyDsGGOtVBD7iflvHMhfWFKtnIj3Q8yPh2c';
```

### Used APIs

1. ✅ Google Maps Flutter (map display)
2. ✅ Geocoding API (address ↔ coordinates)
3. ✅ Places API (location search)
4. ✅ Directions API (route calculation)
5. ✅ Polyline Points (route drawing)

### Default Location

**Jerusalem, Israel:**
```dart
latitude: 31.7683
longitude: 35.2137
```

---

## Dependencies

### Complete List (from pubspec.yaml)

**Total: 30 dependencies**

See [Technology Stack](#technology-stack) section for full list.

---

## Assets

### Asset Structure

```
assets/
├── images/
│   ├── cash.png
│   ├── driver.png
│   └── cars/
│       ├── express.png
│       ├── economy.png
│       ├── xl.png
│       ├── comfort.png
│       └── wassel.png
├── icons/
└── animations/
```

**Declared in pubspec.yaml:**
```yaml
assets:
  - assets/images/
  - assets/images/cash.png
  - assets/images/driver.png
  - assets/images/cars/express.png
  - assets/images/cars/economy.png
  - assets/images/cars/xl.png
  - assets/images/cars/comfort.png
  - assets/images/cars/wassel.png
  - assets/icons/
  - assets/animations/
```

---

## How to Run

### Prerequisites

1. Flutter SDK 3.0+
2. Dart SDK 3.0+
3. Xcode (for iOS)
4. Android Studio (for Android)

### Setup Steps

```bash
# 1. Install dependencies
flutter pub get

# 2. Check setup
flutter doctor

# 3. Run on device
flutter run

# Or specify platform
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

### Build Commands

**Debug:**
```bash
flutter run
```

**Release APK:**
```bash
flutter build apk --release
```

**Release App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## What's Missing (Not in Code)

### Backend
- ❌ No real API endpoints
- ❌ No backend server
- ❌ Using mock data in RideProvider

### Payment
- ❌ No payment gateway (Stripe, PayPal, etc.)
- ❌ WalletScreen is UI only
- ❌ No actual transactions

### Real-time
- ❌ No WebSocket connection
- ❌ No live driver tracking
- ❌ Driver location is static/mock

### Driver Side
- ❌ No driver app
- ❌ No driver matching algorithm
- ❌ No driver acceptance flow

### Advanced Features
- ❌ No in-app chat/messaging
- ❌ No receipt generation
- ❌ No promo code backend
- ❌ No scheduled rides
- ❌ No ride sharing
- ❌ No SOS/emergency features

---

## Summary

### What Works
- ✅ Complete UI (25 screens)
- ✅ Firebase phone authentication
- ✅ Google Maps integration
- ✅ Location services
- ✅ State management (Provider)
- ✅ Navigation
- ✅ Theme & styling

### What's Mock/Simulated
- 🚧 Driver matching (2-second delay, fake drivers)
- 🚧 Ride flow (simulated state changes)
- 🚧 Fare calculation (basic formula)
- 🚧 Driver location (static coordinates)

### What Doesn't Work
- ❌ Payment processing
- ❌ Real backend API
- ❌ Live tracking
- ❌ Driver app integration
- ❌ Chat/messaging
- ❌ Receipt generation

---

**Document Version:** 1.0.0  
**Last Updated:** January 28, 2026  
**Based on:** Actual codebase analysis

*This documentation reflects the current state of the code, not planned features.*
