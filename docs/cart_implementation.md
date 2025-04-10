# ProfitGrocery Cart Implementation

This document explains the cart implementation in ProfitGrocery and recent fixes made to ensure proper persistence and synchronization.

## Architecture

The cart functionality follows a Clean Architecture pattern with multiple layers:

1. **Presentation Layer**
   - `CartBloc`: Manages cart state and handles cart-related events
   - UI Components: CartFAB, CartBadge, etc.

2. **Domain Layer**
   - `CartRepository`: Interface defining cart operations
   - Cart Entities: Data structures for cart items

3. **Data Layer**
   - `CartRepositoryImpl`: Implementation of cart operations
   - `CartRemoteDataSource`: Handles Firebase Realtime Database operations
   - `CartLocalDataSource`: Manages local cart storage with SharedPreferences

4. **Service Layer**
   - `CartSyncService`: Synchronizes local and remote cart data
   - `CartInitializer`: Initializes cart at app startup
   - `HomeCartBridge`: Bridges cart operations between HomeBloc and CartBloc

## Cart Persistence

The application employs a multi-layered persistence strategy:

1. **Local Persistence (SharedPreferences)**
   - Cart data is stored in SharedPreferences for quick local access
   - Provides offline capabilities
   - Data format: JSON representation of CartModel

2. **Remote Persistence (Firebase Realtime Database)**
   - Cart data is stored in Firebase under `users/{userId}/cart`
   - Provides cloud backup and cross-device synchronization
   - Data sync happens automatically when online

## Recent Fixes

We've addressed several issues with the cart functionality:

1. **Cart Visibility Issue**
   - Fixed condition to show cart FAB only when cart has items
   - Added null checks and stricter validation

2. **Cart Persistence Issues**
   - Enhanced CartLocalDataSource with better error handling
   - Improved verification of cached data
   - Added logging for debugging

3. **Firebase Synchronization**
   - Changed from `ref.update()` to `ref.set()` for more reliable updates
   - Added proper verification of database operations
   - Fixed JSON handling and error management

4. **Cart State Management**
   - Added optimistic updates for immediate UI feedback
   - Created HomeCartBridge to ensure cart changes from HomePage properly persist
   - Improved cart initialization at app startup

5. **Better Debugging**
   - Added comprehensive logging throughout cart flow
   - Created debugging guide with troubleshooting steps

## Cart Data Flow

1. User adds item to cart on Product screen
2. HomeCartBridge ensures both HomeBloc and CartBloc are updated
3. CartBloc performs optimistic UI update for responsiveness
4. CartRepositoryImpl handles persistence logic
5. Data is stored locally in SharedPreferences
6. Data is pushed to Firebase when online
7. CartSyncService handles offline operations

## Firebase Realtime Database Structure

Cart data is stored in the following structure:

```
users/
  ├── {userId}/
  │    └── cart/
  │         ├── userId: "user123"
  │         ├── items: [
  │         │    {
  │         │      productId: "prod1",
  │         │      name: "Product Name",
  │         │      image: "image_url",
  │         │      price: 299.99,
  │         │      quantity: 2,
  │         │      ...
  │         │    }
  │         │ ]
  │         ├── appliedCouponId: "coupon123"
  │         ├── appliedCouponCode: "SAVE10"
  │         ├── discount: 29.99
  │         └── deliveryFee: 0.0
```

## Debugging

For detailed debugging information, please refer to the `cart_debugging.md` document.