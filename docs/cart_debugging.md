# Cart Functionality Debugging Guide

This document provides instructions for debugging the cart functionality in the ProfitGrocery application.

## Overview of Added Debugging Logs

We've added comprehensive logging throughout the cart system to help diagnose issues. The logs are categorized by component:

- `CART_BLOC`: Logs from CartBloc showing state changes
- `REMOTE`: Logs from CartRemoteDataSource showing Firebase interactions
- `LOCAL`: Logs from CartLocalDataSource showing local cache operations
- `SYNC`: Logs from CartSyncService showing synchronization process
- `CART_FAB`: Logs from the cart floating action button widget
- `CART_BADGE`: Logs from the cart badge widget
- `HOME_BLOC`: Logs from HomeBloc showing cart quantity updates

## How to Debug the Cart Issues

1. **Enable verbose logging**: Run the app in debug mode with verbose logging enabled:
   ```
   flutter run --verbose
   ```

2. **Monitor the logs**: In the console, monitor logs with the following prefixes:
   - `CART_`
   - `REMOTE`
   - `LOCAL`
   - `SYNC`
   - `HOME_BLOC`

3. **Add to cart**: 
   - Add products to the cart using the "ADD" button on product cards
   - Check logs with prefix `HOME_BLOC` for cart quantity updates
   - Check logs with prefix `CART_BLOC` for cart state updates
   - Check logs with prefix `REMOTE` for Firebase database interactions

4. **Check Firebase Realtime Database**:
   - Open the Firebase console and navigate to the Realtime Database
   - Look for entries under path `cartItems/{sessionId}/{userId}`
   - Verify that data under this path matches the expected cart structure:
   ```
   cartItems/
     └── {sessionId}/
         └── {userId}/
             ├── {productId}/
             │   ├── quantity: 2
             │   ├── addedAt: 1712345678901
             │   └── updatedAt: 1712345789012
             ├── {anotherProductId}/
             │   └── ...
             └── coupon/
                 ├── id: "coupon123"
                 ├── code: "SAVE10"
                 ├── discount: 29.99
                 └── appliedAt: 1712345678901
   ```
   - Check that session ID is consistent with the value logged in console with pattern `Using session ID: xxxx-xxxx-xxxx`
   - Verify that product IDs in the database match those being added to the cart

5. **Check Local Storage**:
   - Check logs with prefix `LOCAL` for cache operations
   - If there are errors related to local storage, they'll appear in logs with pattern `Error caching cart` or `Error parsing cached cart JSON`

6. **Check UI State**:
   - Enable assertiond in Flutter: `flutter run --enable-asserts`
   - Check logs with prefix `CART_FAB` and `CART_BADGE` to see UI component state
   - Verify that `itemCount` is correctly updated in logs

7. **Synchronization Issues**:
   - Check logs with prefix `SYNC` for synchronization process
   - Verify that pending operations are correctly processed
   - Check for connectivity-related errors

## Common Issues and Solutions

1. **Cart widget doesn't update after adding items**:
   - Check if the CartBloc is receiving AddToCart events
   - Check if HomeBloc is updating cartItemCount correctly
   - Verify that CartFAB and FloatingCartBadge are correctly using the itemCount property

2. **Cart shows up even when empty**:
   - Check the "itemCount" value in CartFAB and FloatingCartBadge logs
   - Ensure the condition `itemCount <= 0` is correctly evaluated in both widgets

3. **Firebase database not updating**:
   - Check logs with pattern `Updating cart in Firebase` or `Adding item to cart in Firebase`
   - Verify that Firebase operations complete without errors
   - Check Firebase security rules to ensure write permissions

4. **Network connectivity issues**:
   - Check logs with pattern `Device is offline` or `Network failure`
   - Verify that pending operations are correctly queued when offline
   - Check that operations are processed when connectivity is restored

## Next Steps

If issues persist after reviewing logs:

1. Check if the CartBloc is properly initialized in the dependency injection container
2. Verify that the CartSyncService is correctly initialized during startup
3. Ensure the Firebase Realtime Database is properly configured with correct security rules
4. Test the cart functionality with a simplified user flow, focusing on a single product

For additional help, reach out to the development team with the logs from a debug session.