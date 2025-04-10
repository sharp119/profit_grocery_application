# Cart Implementation Documentation

This document provides an overview of the cart system implementation for the ProfitGrocery application.

## Architecture

The cart implementation follows Clean Architecture principles with three main layers:

1. **Data Layer**
   - Local Data Source: Uses SharedPreferences for persistent local storage
   - Remote Data Source: Connects to Firebase Realtime Database
   - Models: Data models for cart and cart items
   - Repository Implementation: Coordinates between data sources

2. **Domain Layer**
   - Entities: Domain objects representing cart and cart items
   - Repository Interface: Defines contract for repository implementation
   - Use Cases: Not explicitly implemented, but embedded in the BLoC

3. **Presentation Layer**
   - BLoC: Handles state management and business logic
   - UI: Cart page and related widgets

## Key Features

### Offline Support
The cart system works both online and offline:
- When online, changes are saved to Firebase Realtime Database
- When offline, changes are saved locally in SharedPreferences
- Background synchronization when internet connection is restored

### Coupon System
- Validates coupon codes against Firebase database
- Applies different discount types (percentage, fixed amount, conditional)
- Shows relevant validation errors

### Persistence
- Cart state persists between app sessions
- User can close and reopen the app with the same cart state

## Components

### Data Sources

1. **CartLocalDataSource**
   - Responsible for caching cart data locally
   - Uses SharedPreferences for storage
   - Handles serialization/deserialization of cart data

2. **CartRemoteDataSource**
   - Communicates with Firebase Realtime Database
   - Handles CRUD operations for cart data
   - Implements error handling for network issues

### Repository

**CartRepositoryImpl**
- Coordinates between local and remote data sources
- Implements offline-first strategy
- Handles coupon validation via CouponRepository

### Sync Service

**CartSyncService**
- Manages synchronization between local and remote data
- Keeps track of pending operations
- Handles connectivity changes
- Provides sync status updates

### BLoC Pattern

1. **CartBloc**
   - Main class handling cart business logic
   - Manages cart state transitions
   - Handles events from UI and sync service

2. **CartEvent**
   - Defines all possible events: load, add, update, remove, clear, apply coupon, etc.
   - Extends Equatable for proper state comparison

3. **CartState**
   - Holds current cart state: items, totals, coupon info, sync status
   - Extends Equatable for proper state comparison

### UI Components

1. **CartPage**
   - Main cart screen showing cart items, totals, and actions
   - Uses BLoC for state management

2. **CartBadge**
   - Shows cart item count and total in app bar or as floating button
   - Updates in real-time as cart changes

3. **CartSyncIndicator**
   - Displays sync status to users
   - Allows manual sync when needed

## Usage

### Adding Items to Cart

```dart
context.read<CartBloc>().add(
  AddToCart(product, quantity)
);
```

### Updating Item Quantity

```dart
context.read<CartBloc>().add(
  UpdateCartItemQuantity(productId, newQuantity)
);
```

### Removing Items

```dart
context.read<CartBloc>().add(
  RemoveFromCart(productId)
);
```

### Applying Coupon

```dart
context.read<CartBloc>().add(
  ApplyCoupon(couponCode)
);
```

### Clearing Cart

```dart
context.read<CartBloc>().add(
  ClearCart()
);
```

### Force Sync

```dart
context.read<CartBloc>().add(
  ForceSync()
);
```

## Firebase Schema

The cart data is stored in Firebase Realtime Database using the following schema:

```
users/
  - {userId}/
    - cart/
      - items/ (array of cart items)
        - {item}/
          - productId
          - name
          - image
          - price
          - quantity
          - categoryId (optional)
          - categoryName (optional)
      - appliedCouponId
      - appliedCouponCode
      - discount
      - deliveryFee
```

## Future Improvements

1. **Enhanced conflict resolution**
   - Better handling of conflicts between local and remote cart state

2. **Wishlist integration**
   - Allow moving items between cart and wishlist

3. **Personalized recommendations**
   - Suggest related items based on cart contents

4. **Cart item notes**
   - Allow users to add notes to specific cart items

5. **Advanced discounting rules**
   - Support for more complex coupon and discount rules
