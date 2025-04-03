# ProfitGrocery

A premium mobile e-commerce application designed for online grocery shopping with an innovative coupon-based offer system and WhatsApp marketing integration.

![ProfitGrocery](assets/images/logo.png)

## Overview

ProfitGrocery is built with Flutter using Clean Architecture principles and the BLoC pattern. The application features a sleek black and gold design with a dense grid UI layout, giving users the impression of a vast selection of products while maintaining a premium look and feel.

## Features

### Customer-Facing Features

- **Secure Authentication**
  - Phone number based authentication with OTP verification
  - Custom OTP service integration with MSG91

- **Product Browsing and Navigation**
  - Category-based product listing with hierarchical navigation
  - Dense grid layout with essential product details
  - Basic product filtering and search functionality

- **Shopping Experience**
  - Intuitive shopping cart functionality
  - Streamlined checkout process
  - Order history and tracking

- **Innovative Offer System**
  - Manual coupon code entry
  - Various discount types (percentage, fixed amount, free products)
  - WhatsApp marketing integration with deep linking
  - Conditional discounts based on purchase amount

### Admin Panel Features

- **Product Management**
  - Basic CRUD operations for products
  - Category assignment and stock status management

- **Order Management**
  - Order list viewing and status updates
  - Delivery status tracking

- **Offer Management**
  - Manual coupon creation with various parameters
  - WhatsApp link generation for marketing

## Architecture

ProfitGrocery follows Clean Architecture principles with the BLoC pattern to ensure:

- Clear separation of concerns
- Testability of individual components
- Scalability for future feature enhancements
- Maintainability through organized code structure

### Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── blocs/
│   ├── pages/
│   └── widgets/
├── services/
└── main.dart
```

## Installation and Setup

### Prerequisites

- Flutter SDK 3.6.0 or higher
- Android Studio / VS Code
- Firebase account
- MSG91 account for OTP services

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/sharp119/profit_grocery_application.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project
   - Add Android app with package name `com.profitgrocery.app`
   - Download `google-services.json` and place in `android/app/`
   - Enable Firebase services (Database, Storage, Remote Config)

4. Configure OTP service:
   - Get API credentials from MSG91
   - Update constants in `lib/services/otp_service.dart`

5. Run the application:
   ```bash
   flutter run
   ```

## Key Technologies

- **Flutter & Dart** - Cross-platform app development
- **Flutter BLoC** - State management
- **Firebase** - Backend services
  - Realtime Database
  - Storage
  - Remote Config
- **Custom OTP Authentication** - Using MSG91 services
- **GetIt** - Dependency injection
- **Equatable** - Value equality
- **Dartz** - Functional programming constructs

## Authentication Flow

ProfitGrocery uses a custom phone number verification flow:

1. User enters their phone number
2. OTP is sent to the phone via MSG91 service
3. User enters the 4-digit OTP code
4. OTP is verified and user is authenticated
5. User ID is stored in SharedPreferences for persistence

## UI Design

The application features a premium black and gold color scheme with a "Dense Grid UI" layout:

- **Grid-Based Layout** - Items organized in tightly packed grids
- **Minimal White Space** - High information density
- **Icon + Text Combination** - Quick readability
- **Bright & High-Contrast Visuals** - Bold, colorful images

## Firebase Integration

ProfitGrocery leverages several Firebase services:

- **Realtime Database** - For storing product, order, and user data
- **Remote Config** - For dynamic configuration of app features
- **Storage** - For storing product images and other assets

## Contributing

We welcome contributions to the ProfitGrocery project! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Built with ❤️ for premium grocery shopping experiences