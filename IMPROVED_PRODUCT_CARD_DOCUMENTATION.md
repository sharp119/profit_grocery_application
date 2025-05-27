# Improved Product Card & Horizontal Bestseller Grid Documentation

This documentation explains the implementation of the new `ImprovedProductCard` and `HorizontalBestsellerGrid` components that provide enhanced flexibility and performance for product display throughout the application.

## Overview

The new components address the requirement for:
- **Reusable product cards** that work with any product ID
- **Horizontally scrollable grids** for bestsellers section
- **Consistent layout structure** across all product displays
- **Optimized performance** with caching and lazy loading

## Components

### 1. ImprovedProductCard

A highly flexible product card component that can work with either a `Product` object or just a `productId` string.

#### Key Features

- **Flexible Initialization**: Works with Product object OR productId
- **Automatic Product Resolution**: Resolves product details from ID automatically
- **Fixed Width Support**: Perfect for horizontal scrolling layouts
- **Category-based Colors**: Automatic background color from product category
- **Savings Indicator**: Bookmark-style discount display
- **Customizable Layout**: Enable/disable specific sections as needed

#### Layout Structure

The card follows the specified layout structure:

```
┌─────────────────────────────┐
│     Image Section (~60%)    │ ← Product image with savings indicator
│                             │
├─────────────────────────────┤
│ Product Name (up to 2 lines│ ← Product name with ellipsis
├─────────────────────────────┤
│ Brand           Weight      │ ← Brand (left) and Weight (right)
├─────────────────────────────┤
│      Empty Spacer Row       │ ← Visual separation
├─────────────────────────────┤
│ ₹Final   ₹Original         │ ← Price row with strikethrough
├─────────────────────────────┤
│      Add to Cart Button     │ ← Centered button
└─────────────────────────────┘
```

#### Usage Examples

```dart
// Basic usage with Product object
ImprovedProductCard(
  product: product,
  onTap: () => navigateToDetails(product),
  onQuantityChanged: (product, qty) => updateCart(product, qty),
)

// Usage with product ID only (auto-resolves)
ImprovedProductCard(
  productId: "product_123",
  onTap: () => navigateToDetails(),
)

// Fixed width for horizontal scrolling
ImprovedProductCard(
  product: product,
  width: 180.w,
  height: 280.h,
  onTap: () => navigateToDetails(product),
)

// Custom pricing override (for promotions)
ImprovedProductCard(
  product: product,
  finalPrice: 199.0,
  originalPrice: 299.0,
  hasDiscount: true,
  discountType: 'flat',
  discountValue: 100.0,
)
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `product` | `Product?` | `null` | Product object (either this or productId required) |
| `productId` | `String?` | `null` | Product ID to resolve (either this or product required) |
| `width` | `double?` | `180.w` | Fixed width for horizontal layouts |
| `height` | `double?` | `280.h` | Fixed height override |
| `backgroundColor` | `Color?` | `null` | Background color override |
| `finalPrice` | `double?` | `null` | Override final price |
| `originalPrice` | `double?` | `null` | Override original price |
| `hasDiscount` | `bool?` | `null` | Override discount status |
| `discountType` | `String?` | `null` | 'percentage' or 'flat' |
| `discountValue` | `double?` | `null` | Discount amount |
| `onTap` | `VoidCallback?` | `null` | Card tap callback |
| `onQuantityChanged` | `Function(Product, int)?` | `null` | Quantity change callback |
| `quantity` | `int` | `0` | Current cart quantity |
| `showBrand` | `bool` | `true` | Show brand row |
| `showWeight` | `bool` | `true` | Show weight in row |
| `showSavingsIndicator` | `bool` | `true` | Show savings badge |
| `enableQuantityControls` | `bool` | `true` | Enable add to cart button |

### 2. HorizontalBestsellerGrid

A horizontally scrollable grid specifically designed for the bestsellers section with optimized performance.

#### Key Features

- **Horizontal Scrolling**: Shows 2 full cards + part of 3rd for scroll indication
- **Dynamic Loading**: Loads more items as user scrolls (pagination)
- **Real-time Updates**: Optional RTDB integration for live updates
- **Multiple Data Sources**: Supports both RTDB and simple repository
- **Performance Optimized**: Lazy loading and efficient rendering

#### Layout Specifications

- **Card Width**: `180.w` (fixed for consistent spacing)
- **Visible Cards**: 2.3 cards (2 full + 0.3 partial for scroll hint)
- **Spacing**: `16.w` between cards
- **Padding**: `16.w` horizontal margins
- **Height**: Responsive based on card content

#### Usage Examples

```dart
// Basic horizontal grid
HorizontalBestsellerGrid(
  onProductTap: (product) => navigateToProduct(product),
  onQuantityChanged: (product, qty) => updateCart(product, qty),
  cartQuantities: cartQuantities,
  limit: 12,
  useRealTimeUpdates: true,
)

// Complete section with header
HorizontalBestsellerSection(
  title: 'Bestsellers',
  viewAllText: 'View All',
  onViewAllTap: () => navigateToAllBestsellers(),
  onProductTap: (product) => navigateToProduct(product),
  onQuantityChanged: (product, qty) => updateCart(product, qty),
  cartQuantities: cartQuantities,
  limit: 12,
  useRealTimeUpdates: true,
  showBestsellerBadge: true,
)
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `onProductTap` | `Function(Product)?` | `null` | Product tap callback |
| `onQuantityChanged` | `Function(Product, int)?` | `null` | Quantity change callback |
| `cartQuantities` | `Map<String, int>?` | `null` | Current cart quantities |
| `limit` | `int` | `12` | Maximum items to load |
| `ranked` | `bool` | `false` | Sort by rank vs random |
| `useRealTimeUpdates` | `bool` | `true` | Enable RTDB real-time updates |
| `showBestsellerBadge` | `bool` | `false` | Show savings indicators |
| `cardWidth` | `double` | `180.0` | Fixed card width |
| `cardHeight` | `double` | `280.0` | Fixed card height |
| `spacing` | `double` | `16.0` | Spacing between cards |
| `padding` | `EdgeInsets?` | `null` | Container padding |
| `useRTDB` | `bool` | `true` | Use RTDB vs simple repository |

## Implementation Guide

### Step 1: Home Screen Integration

Replace the existing vertical bestseller grid with the new horizontal implementation:

```dart
// OLD: Vertical grid
RTDBBestsellerGrid(
  onProductTap: _onProductTap,
  onQuantityChanged: _handleAddToCart,
  cartQuantities: state.cartQuantities,
  crossAxisCount: 2,
  // ... other parameters
)

// NEW: Horizontal scrollable section
HorizontalBestsellerSection(
  title: 'Bestsellers',
  viewAllText: 'View All',
  onViewAllTap: () => navigateToAllBestsellers(),
  onProductTap: _onProductTap,
  onQuantityChanged: _handleAddToCart,
  cartQuantities: state.cartQuantities,
  limit: 12,
  useRealTimeUpdates: true,
  showBestsellerBadge: true,
)
```

### Step 2: Individual Product Cards

Use the improved product card for consistent display:

```dart
// Standard product display
ImprovedProductCard(
  product: product,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailsPage(productId: product.id),
    ),
  ),
  onQuantityChanged: (product, qty) {
    // Update cart logic
    context.read<CartBloc>().add(UpdateCartQuantity(product, qty));
  },
  quantity: cartQuantities[product.id] ?? 0,
)
```

### Step 3: Custom Horizontal Grids

Create custom horizontal product grids:

```dart
SizedBox(
  height: 280.h,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: products.length,
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    itemBuilder: (context, index) {
      return Container(
        width: 180.w,
        margin: EdgeInsets.only(right: 16.w),
        child: ImprovedProductCard(
          product: products[index],
          onTap: () => handleProductTap(products[index]),
          onQuantityChanged: handleQuantityChange,
          quantity: cartQuantities[products[index].id] ?? 0,
        ),
      );
    },
  ),
)
```

## Migration from Existing Cards

### From ReusableProductCard

```dart
// OLD
ReusableProductCard(
  product: product,
  finalPrice: finalPrice,
  originalPrice: originalPrice,
  hasDiscount: hasDiscount,
  backgroundColor: backgroundColor,
  onTap: onTap,
)

// NEW
ImprovedProductCard(
  product: product,
  finalPrice: finalPrice,
  originalPrice: originalPrice,
  hasDiscount: hasDiscount,
  backgroundColor: backgroundColor,
  onTap: onTap,
  onQuantityChanged: onQuantityChanged, // New feature
)
```

### From UniversalProductCard

```dart
// OLD
UniversalProductCard(
  productId: productId,
  onTap: onTap,
  backgroundColor: backgroundColor,
)

// NEW
ImprovedProductCard(
  productId: productId,
  onTap: onTap,
  backgroundColor: backgroundColor,
  // Additional customization options available
)
```

## Performance Considerations

### 1. Product Resolution Caching

The `ImprovedProductCard` uses `SharedProductService` for efficient product resolution with automatic caching.

### 2. Horizontal Scrolling Optimization

- Fixed card dimensions prevent layout calculations during scroll
- Lazy loading reduces initial render time
- Pagination loads additional items as needed

### 3. Real-time Updates

- RTDB streams provide live data updates
- Automatic state management handles data changes
- Fallback to static loading if real-time fails

## Testing

### Unit Tests

Test individual components:

```dart
testWidgets('ImprovedProductCard displays product correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ImprovedProductCard(
        product: testProduct,
        onTap: () {},
      ),
    ),
  );
  
  expect(find.text(testProduct.name), findsOneWidget);
  expect(find.text('₹${testProduct.price.toStringAsFixed(0)}'), findsOneWidget);
});
```

### Integration Tests

Test horizontal scrolling behavior:

```dart
testWidgets('HorizontalBestsellerGrid scrolls horizontally', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HorizontalBestsellerGrid(
          onProductTap: (product) {},
        ),
      ),
    ),
  );
  
  // Test horizontal scroll
  await tester.drag(find.byType(ListView), Offset(-200, 0));
  await tester.pumpAndSettle();
  
  // Verify scroll occurred
  expect(find.byType(ImprovedProductCard), findsWidgets);
});
```

## Examples

See `lib/presentation/pages/examples/improved_product_card_examples.dart` for complete working examples of all use cases.

## Best Practices

### 1. Consistent Sizing

Use standard dimensions for horizontal grids:
- Card Width: `180.w`
- Card Height: `280.h`
- Spacing: `16.w`

### 2. Error Handling

Always provide fallback states:
- Loading state during product resolution
- Error state for failed loads
- Empty state for no data

### 3. Performance

- Use `productId` when possible for lazy loading
- Implement proper cart state management
- Handle quantity changes efficiently

### 4. Accessibility

- Provide semantic labels for screen readers
- Ensure sufficient color contrast
- Support keyboard navigation

## Troubleshooting

### Common Issues

1. **Product not found**: Ensure productId exists in SharedProductService
2. **Layout overflow**: Check container constraints and card dimensions
3. **Performance issues**: Verify efficient cart state management
4. **Real-time updates not working**: Check RTDB connection and permissions

### Debug Tips

- Enable logging in components for detailed information
- Use Flutter Inspector to verify layout structure
- Test with various product data scenarios
- Monitor performance with Flutter DevTools

## Future Enhancements

1. **Wishlist Integration**: Add wishlist toggle functionality
2. **Enhanced Animations**: Smooth transitions and micro-interactions
3. **A/B Testing**: Support for different layout variants
4. **Advanced Filtering**: Category-specific display options
5. **Offline Support**: Cache for offline product display
