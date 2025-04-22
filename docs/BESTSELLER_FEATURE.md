# Enhanced Bestseller Feature Documentation

This document provides an overview of the enhanced bestseller feature implementation for the ProfitGrocery application. The feature allows showcasing bestselling products with their special discounts.

## Table of Contents
1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Implementation Details](#implementation-details)
4. [Components](#components)
5. [Usage Examples](#usage-examples)
6. [Testing](#testing)

## Overview
The bestseller feature displays products marked as bestsellers across the app. The enhanced implementation now supports:

- Bestseller-specific discounts (percentage or flat amount)
- Proper discount calculation and display
- Visual indicators for bestseller products
- Organized data architecture using Clean Architecture principles

## Database Schema
The implementation follows the Firestore schema described in `ProfitGrocery_Firestore_Schema_Bestsellers.md`.

```
## Root Collection: bestsellers
collection('bestsellers')

  ## Document: product ID (e.g., "0hDdYOX7FB5UDUs1Gbe6")
  document('{productId}')

    ### Bestseller Details
    {
      discountType: String,      # "percentage" or "flat"
      discountValue: Number,     # 10
      rank: Number               # 19
    }
```

Key aspects:
- Document ID in the bestsellers collection matches the product ID in the products collection
- `rank` field determines the display order (lower values appear first)
- `discountType` can be "percentage" or "flat"
- `discountValue` contains the discount amount (percentage or flat amount)

## Implementation Details

### Entity Models
- `BestsellerItem`: Represents a bestseller entry with product ID, rank, and discount information
- `BestsellerProduct`: Combines a Product with a BestsellerItem, handling discount calculations

### Repository
- `BestsellerRepositorySimple`: Fetches bestseller items with their discount information

### UI Components
- `BestsellerProductCard`: Specialized product card that displays bestseller badges and discounts
- `SimpleBestsellerGrid`: Grid layout that displays bestseller products

## Components

### BestsellerItem
```dart
class BestsellerItem extends Equatable {
  final String productId;
  final int rank;
  final String? discountType;
  final double? discountValue;
  
  const BestsellerItem({
    required this.productId,
    required this.rank,
    this.discountType,
    this.discountValue,
  });
  
  /// Check if this bestseller has a special discount
  bool get hasSpecialDiscount => 
    discountType != null && 
    discountValue != null && 
    discountValue! > 0;
  
  /// Calculate the discounted price based on original price
  double getDiscountedPrice(double originalPrice) {
    if (!hasSpecialDiscount) return originalPrice;
    
    if (discountType == 'percentage') {
      final discount = originalPrice * (discountValue! / 100);
      return originalPrice - discount;
    } else if (discountType == 'flat') {
      return originalPrice - discountValue!;
    }
    
    return originalPrice;
  }
}
```

### BestsellerProduct
```dart
class BestsellerProduct extends Equatable {
  final Product product;
  final BestsellerItem bestsellerInfo;
  
  const BestsellerProduct({
    required this.product,
    required this.bestsellerInfo,
  });
  
  /// Get final price after applying bestseller discount
  double get finalPrice => hasSpecialDiscount
      ? bestsellerInfo.getDiscountedPrice(product.price)
      : product.price;
  
  /// Get total discount percentage (after applying bestseller discount)
  double get totalDiscountPercentage {
    if (mrp == null || mrp! <= finalPrice) {
      return 0.0;
    }
    return ((mrp! - finalPrice) / mrp! * 100).roundToDouble();
  }
}
```

### BestsellerRepositorySimple
```dart
class BestsellerRepositorySimple {
  final FirebaseFirestore _firestore;
  
  Future<List<BestsellerItem>> getBestsellerItems({
    int limit = 12,
    bool ranked = false,
  }) async {
    // Retrieves bestseller items with their discount information
  }
}
```

### SimpleBestsellerGrid
```dart
class SimpleBestsellerGrid extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;
  final bool showBestsellerBadge;

  const SimpleBestsellerGrid({
    Key? key,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 12,
    this.ranked = false,
    this.crossAxisCount = 2,
    this.showBestsellerBadge = true,
  }) : super(key: key);
}
```

## Usage Examples

### Basic Grid Usage
```dart
SimpleBestsellerGrid(
  onProductTap: (product) {
    // Handle product tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(productId: product.id),
      ),
    );
  },
  onQuantityChanged: (product, quantity) {
    // Handle quantity changes (add to cart, etc.)
    cartBloc.add(UpdateCartItemEvent(
      productId: product.id,
      quantity: quantity,
    ));
  },
  cartQuantities: cartBloc.state.cartQuantities,
  limit: 6,  // Show 6 bestsellers
  ranked: true,  // Sort by rank
  crossAxisCount: 2,  // 2 products per row
)
```

### Manual Creation Example
```dart
// Create a sample product
final product = Product(
  id: 'custom-product-1',
  name: 'Premium Chocolate Cookies',
  price: 150.0,
  mrp: 180.0,
  image: 'https://example.com/cookies.jpg',
  categoryId: 'bakeries_biscuits',
  inStock: true,
);

// Create a bestseller item with percentage discount
final bestsellerItem = BestsellerItem(
  productId: product.id,
  rank: 1,
  discountType: 'percentage',
  discountValue: 15.0, // 15% off
);

// Create the BestsellerProduct by combining the two
final bestsellerProduct = BestsellerProduct(
  product: product,
  bestsellerInfo: bestsellerItem,
);

// Use in a BestsellerProductCard
BestsellerProductCard(
  bestsellerProduct: bestsellerProduct,
  backgroundColor: Colors.blue.shade800,
  quantity: 0,
  onTap: (bp) => handleProductTap(bp.product),
  onQuantityChanged: (bp, qty) => handleQuantityChanged(bp.product, qty),
  showBestsellerBadge: true,
)
```

## Testing
A detailed example implementation is available for testing the bestseller feature:

1. Navigate to the Developer Menu from the profile section
2. Select "Bestseller Example" to see the working implementation
3. Test different discount scenarios and interactions

The example shows:
- Grid display of bestseller products
- Individual bestseller card with discount details
- Pricing breakdown showing how discounts are calculated
- Cart interaction functionality
