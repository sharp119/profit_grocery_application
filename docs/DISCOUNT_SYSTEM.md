# ProfitGrocery Discount System

This document explains the new modular discount system implemented in ProfitGrocery.

## Overview

The discount system has been completely refactored to be:
- **Independent** from specific product types (bestsellers, regular products, etc.)
- **Modular** with a clear separation of concerns
- **Reusable** across different parts of the application
- **Consistent** in how discounts are calculated and displayed

## Key Components

### 1. Discount Service (`discount_service.dart`)

The core service responsible for accessing discount information from different sources:

```dart
// Get discount for a single product
final discountInfo = await DiscountService().getDiscountForProduct(product);

// Get discounts for multiple products at once
final discountMap = await DiscountService().getDiscountsForProducts(productList);
```

### 2. Discount Info (`discount_info.dart`)

A data class that represents the result of discount lookups:

```dart
final discountInfo = DiscountInfo(
  productId: 'product123',
  hasDiscount: true,
  discountType: 'percentage',
  discountValue: 15.0,
  originalPrice: 100.0,
  finalPrice: 85.0,
  source: 'bestseller',
);
```

### 3. Discount Calculator (`discount_calculator.dart`)

A utility class with pure functions for discount calculations:

```dart
// Calculate percentage discount
final discountedPrice = DiscountCalculator.calculatePercentageDiscount(
  originalPrice: 100.0,
  percentageValue: 15.0, // 15% off
);

// Calculate flat discount
final discountedPrice = DiscountCalculator.calculateFlatDiscount(
  originalPrice: 100.0,
  flatValue: 20.0, // ₹20 off
);

// Calculate with automatic type detection
final discountedPrice = DiscountCalculator.calculateDiscountedPrice(
  originalPrice: 100.0,
  discountType: 'percentage',
  discountValue: 15.0,
);

// Format discount for display
final displayText = DiscountCalculator.formatDiscountForDisplay(
  discountType: 'percentage',
  discountValue: 15.0,
); // "15% OFF"
```

### 4. Discount Model (`discount_model.dart`)

A comprehensive model to represent discount information in the UI layer:

```dart
// Create a model with percentage discount
final discount = DiscountModel.percentage(
  productId: 'product123',
  originalPrice: 100.0,
  percentageValue: 15.0,
  source: 'promo',
);

// Create a model with flat discount
final discount = DiscountModel.flat(
  productId: 'product123',
  originalPrice: 100.0,
  flatValue: 20.0,
  source: 'coupon',
);

// Access computed properties
final hasDiscount = discount.hasDiscount;
final discountPercentage = discount.discountPercentage;
final discountAmount = discount.discountAmount;
final formattedDiscount = discount.formattedDiscount;
```

### 5. Discount Provider (`discount_provider.dart`)

A facade for the discount service, with caching:

```dart
// Get discount for a product
final discount = await DiscountProvider().getDiscount(product);

// Get discounts for multiple products
final discounts = await DiscountProvider().getDiscounts(productList);

// Check if a product has a discount
final hasDiscount = await DiscountProvider().hasDiscount(product);

// Get final price
final price = await DiscountProvider().getFinalPrice(product);

// Apply a custom discount
final customDiscount = DiscountProvider().applyCustomDiscount(
  product: product,
  discountType: 'percentage',
  discountValue: 25.0,
  source: 'flash_sale',
);

// Clear cache
DiscountProvider().clearCache(); // Clear all
DiscountProvider().clearCache(productId: 'product123'); // Clear specific
```

## UI Components

### Modern Product Card

The `ModernProductCard` is a ready-to-use component that handles discount fetching automatically:

```dart
ModernProductCard(
  product: product,
  backgroundColor: Colors.blue,
  onTap: (product) {
    // Handle tap
  },
  quantity: cartQuantity,
  onQuantityChanged: (product, quantity) {
    // Handle quantity change
  },
)
```

## Discount Lifecycle

1. **Fetching**: Discounts are fetched from multiple sources in order of priority:
   - Bestseller-specific discounts
   - Regular product discounts

2. **Validation**: Discounts are validated based on:
   - Active status
   - Time validity (start/end dates)
   - Valid discount values

3. **Calculation**: Prices are calculated based on discount type:
   - Percentage: `finalPrice = originalPrice - (originalPrice * (percentageValue / 100))`
   - Flat: `finalPrice = originalPrice - flatValue`

4. **Display**: Discount information is displayed consistently across the app:
   - Percentage: "15% OFF"
   - Flat: "₹20 OFF"
   - Strikethrough original price

## Architecture Flow

```
Data Layer      |     Service Layer     |     UI Layer
----------------|----------------------|---------------
Firebase        |  DiscountService     |  ModernProductCard
 ↑              |   ↑        ↓         |   ↑
Firestore       |  DiscountInfo        |  BestsellerProductCard
                |   ↑        ↓         |   ↑
                |  DiscountCalculator  |   ↓
                |   ↑        ↓         |  ReusableProductCard
                |  DiscountProvider    |
                |          ↓           |
                |  DiscountModel       |
```

## Migration Guide

### From Legacy Bestseller System

Replace:

```dart
BestsellerProductCard(
  bestsellerProduct: bestsellerProduct,
  backgroundColor: Colors.blue,
)
```

With:

```dart
ModernProductCard(
  product: bestsellerProduct.product,
  backgroundColor: Colors.blue,
)
```

### Direct Discount Access

Instead of manually calculating discounts:

```dart
// Old approach - manually calculating
final price = product.price;
final discount = product.price * 0.15;
final finalPrice = price - discount;
```

Use the discount provider:

```dart
// New approach - using the discount system
final discount = await DiscountProvider().getDiscount(product);
final finalPrice = discount.finalPrice;
```

## Example Usage

### Simple Product Display

```dart
Future<Widget> buildProductCard(Product product) async {
  final discount = await DiscountProvider().getDiscount(product);
  
  return Card(
    child: Column(
      children: [
        Text(product.name),
        Text('${discount.finalPrice}'),
        if (discount.hasDiscount)
          Text('${discount.formattedDiscount}'),
      ],
    ),
  );
}
```

### Batch Processing

```dart
Future<void> processBatchDiscounts(List<Product> products) async {
  // Get all discounts in one call
  final discounts = await DiscountProvider().getDiscounts(products);
  
  // Process each product with its discount
  for (final product in products) {
    final discount = discounts[product.id];
    if (discount != null && discount.hasDiscount) {
      print('${product.name}: ${discount.formattedDiscount}');
    }
  }
}
```

## Error Handling

The discount system is designed to be resilient:

1. If a discount lookup fails, the system returns a no-discount model
2. If discount data is malformed, the system safely handles it
3. Time validity is checked with robust parsing for different timestamp formats
4. The discount value parser handles multiple types (int, double, String)

Example of safe error handling:

```dart
try {
  final discount = await DiscountProvider().getDiscount(product);
  // Use discount
} catch (e) {
  // This should never happen due to internal error handling
  print('Error getting discount: $e');
  // Fallback to no discount
  final noDiscount = DiscountModel.noDiscount(
    productId: product.id,
    price: product.price,
  );
}
```