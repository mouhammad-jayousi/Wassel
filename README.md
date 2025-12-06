# Wassel Rider App - Flutter Prototype

A modern, mobile-friendly taxi booking app built with Flutter, featuring a clean design with a fresh green color scheme.

## 🎯 Current Status

This is a **working prototype** (V0.1) with the following features implemented:

### ✅ Completed Features
- **Splash Screen** - App branding and loading
- **Onboarding** - 3-screen introduction to the app
- **Authentication**
  - Sign In with phone number
  - Sign Up screen
  - OTP Verification with custom number pad
  - Social login buttons (UI only)
- **Home Screen**
  - Map placeholder
  - Current location display
  - Search bar
  - Saved places (Home, Work, Favorite)
- **Profile/Menu Screen**
  - User profile display
  - Menu items (Wallet, History, Settings, etc.)
  - Logout functionality
- **State Management** - Provider pattern
- **Navigation** - Custom routing system
- **Theme** - Green color scheme matching Figma designs

### 🚧 To Be Implemented
- Google Maps integration
- Location search with autocomplete
- Ride selection and booking
- Real-time ride tracking
- Payment integration
- Firebase backend
- Push notifications
- And more...

## 📱 Screenshots

The app is designed based on the Figma templates provided, featuring:
- Clean, modern UI
- Green/teal color scheme (#3DD598)
- Smooth animations
- Mobile-first design

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Navigation**: Custom routing
- **UI**: Material Design 3
- **Dependencies**: See `pubspec.yaml`

## 🚀 Getting Started

### Prerequisites

1. Install Flutter SDK (3.0 or higher)
   ```bash
   # Check Flutter installation
   flutter doctor
   ```

2. Install dependencies
   ```bash
   cd greenride_app
   flutter pub get
   ```

### Running the App

#### iOS Simulator
```bash
flutter run -d ios
```

#### Android Emulator
```bash
flutter run -d android
```

#### Chrome (Web - for testing)
```bash
flutter run -d chrome
```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```

#### iOS IPA
```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── theme.dart           # App theme and colors
│   └── routes.dart          # Navigation routes
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   ├── location_provider.dart # Location state
│   └── ride_provider.dart   # Ride state
├── screens/
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── ride/
│   └── profile/
└── widgets/                  # Reusable widgets (to be added)
```

## 🎨 Design System

### Colors
- **Primary Green**: #3DD598
- **Primary Dark**: #2BC184
- **Primary Light**: #E8F5F0
- **Accent Blue**: #5B6EF5
- **Text Dark**: #2C3E50
- **Text Medium**: #7F8C8D
- **Background**: #F5F5F5

### Typography
- Font: System default (San Francisco on iOS, Roboto on Android)
- Headings: Bold (700)
- Body: Regular (400)
- Buttons: Semi-bold (600)

## 🔄 Next Steps

1. **Week 1-2**: Integrate Google Maps and location services
2. **Week 3-4**: Implement ride booking flow
3. **Week 5-6**: Add Firebase backend
4. **Week 7-8**: Payment integration (Stripe)
5. **Week 9-10**: Real-time tracking with WebSocket
6. **Week 11-12**: Testing and deployment

## 📝 Notes

- This is a prototype/MVP version
- Some features are UI-only (no backend integration yet)
- Mock data is used for demonstration
- Firebase, Google Maps, and payment integrations are planned for next phases

## 🐛 Known Issues

- Map view is a placeholder (Google Maps not integrated yet)
- Location search is not functional
- OTP verification uses mock data
- No actual backend API calls

## 📄 License

This project is part of the Wassel taxi app development.

## 👥 Team

- Development: In Progress
- Design: Based on Figma templates
- Backend: To be implemented

---

**Version**: 0.1.0 (Prototype)
**Last Updated**: 2025-10-16
