# Improved Product Card Implementation

## 🎯 Overview

This implementation provides a complete solution for displaying products in a horizontally scrollable grid format, specifically designed for the bestsellers section on the home screen. The solution includes two main components:

1. **ImprovedProductCard** - A highly flexible, reusable product card
2. **HorizontalBestsellerGrid** - A horizontally scrollable grid optimized for bestsellers

## ✨ Key Features

### ImprovedProductCard Features
- ✅ Works with `Product` object OR `productId` string
- ✅ Fixed width layout perfect for horizontal scrolling
- ✅ Automatic product resolution and caching
- ✅ Category-based background colors
- ✅ Bookmark-style savings indicator
- ✅ Smart discount calculation (₹X off / X% off)
- ✅ Responsive layout with proper text truncation
- ✅ Loading, error, and empty states
- ✅ Add to cart functionality with quantity controls

### HorizontalBestsellerGrid Features
- ✅ Shows 2 full cards + partial 3rd card for scroll indication
- ✅ Dynamic pagination with lazy loading
- ✅ Real-time RTDB updates
- ✅ Smooth horizontal scrolling performance
- ✅ Configurable card dimensions and spacing
- ✅ Error handling and retry mechanisms
- ✅ Integrated cart quantity management

## 📐 Layout Structure

The product card follows the specified layout requirements:

```
┌─────────────────────────────┐
│     Image Section (~60%)    │ ← Product image + savings indicator
│        [Savings Badge]      │   (Bookmark style in top-right)
├─────────────────────────────┤
│ Product Name (up to 2 lines│ ← Truncated with ellipsis
├─────────────────────────────┤
│ Brand           Weight      │ ← Split layout
├─────────────────────────────┤
│      Empty Spacer Row       │ ← Visual separation
├─────────────────────────────┤
│ ₹Final   ₹Original         │ ← Price with strikethrough
├─────────────────────────────┤
│      Add to Cart Button     │ ← Centered, full width
└─────────────────────────────┘
```

## 📱 Visual Layout

### Horizontal Scrolling Behavior
- **Card Width**: 180.w (fixed)
- **Visible Cards**: 2.3 cards (2 full + 0.3 partial)
- **Spacing**: 16.w between cards
- **Padding**: 16.w horizontal margins

```
[Card 1]  [Card 2]  [Par...] → Scroll indicator
  180w      180w      60w
```

### Savings Indicator Design
```
┌─────────────────┐
│     Product     │
│     Image       │ ┌────┐
│                 │ │50% │ ← Bookmark style
│                 │ │OFF │   Red background
└─────────────────┘ └────┘   White text
```

## 🚀 Quick Start

### 1. Replace Existing Bestseller Grid

In your home page, replace the vertical bestseller grid:

```dart
// OLD: Vertical grid
RTDBBestsellerGrid(
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

### 2. Use Individual Product Cards

For other product displays throughout the app:

```dart
// With Product object
ImprovedProductCard(
  product: product,
  onTap: () => navigateToDetails(product),
  onQuantityChanged: (product, qty) => updateCart(product, qty),
  quantity: cartQuantities[product.id] ?? 0,
)

// With just product ID (auto-resolves)
ImprovedProductCard(
  productId: "product_123",
  onTap: () => navigateToDetails(),
)

// Loading state (no product resolution)
ImprovedProductCard.loading(
  width: 180.w,
  height: 280.h,
)
```

## 🛠️ Configuration Options

### Card Customization

```dart
ImprovedProductCard(
  product: product,
  width: 180.w,                    // Fixed width
  height: 280.h,                   // Fixed height
  backgroundColor: Colors.blue,     // Override background
  finalPrice: 199.0,               // Override price
  originalPrice: 299.0,            // Override original price
  hasDiscount: true,               // Override discount status
  discountType: 'flat',            // 'percentage' or 'flat'
  discountValue: 100.0,            // Discount amount
  showBrand: true,                 // Show/hide brand
  showWeight: true,                // Show/hide weight
  showSavingsIndicator: true,      // Show/hide savings badge
  enableQuantityControls: true,    // Enable/disable cart controls
)
```

### Grid Configuration

```dart
HorizontalBestsellerGrid(
  limit: 12,                       // Max items to load
  ranked: false,                   // Sort by rank vs random
  useRealTimeUpdates: true,        // Enable RTDB real-time
  showBestsellerBadge: true,       // Show savings indicators
  cardWidth: 180.0,                // Card width
  cardHeight: 280.0,               // Card height
  spacing: 16.0,                   // Spacing between cards
  useRTDB: true,                   // Use RTDB vs simple repo
)
```

## 📊 Performance Optimizations

### 1. Product Resolution Caching
- Uses `SharedProductService` for efficient caching
- Automatic product resolution from ID
- Reduces redundant network calls

### 2. Horizontal Scrolling
- Fixed card dimensions prevent layout recalculations
- Lazy loading with pagination
- Optimized scroll physics

### 3. Real-time Updates
- RTDB streams for live data
- Automatic state management
- Fallback to static loading

## 🧪 Testing

### Running Examples

Navigate to the examples page to see all use cases:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ImprovedProductCardExamples(),
  ),
);
```

### Unit Testing

```dart
testWidgets('ImprovedProductCard displays correctly', (tester) async {
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

## 📚 API Reference

### ImprovedProductCard Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `product` | `Product?` | `null` | Product object |
| `productId` | `String?` | `null` | Product ID to resolve |
| `isLoading` | `bool` | `false` | Explicit loading state |
| `width` | `double?` | `180.w` | Fixed width |
| `height` | `double?` | `280.h` | Fixed height |
| `onTap` | `VoidCallback?` | `null` | Card tap callback |
| `onQuantityChanged` | `Function(Product, int)?` | `null` | Quantity change callback |
| `showSavingsIndicator` | `bool` | `true` | Show savings badge |

### HorizontalBestsellerGrid Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `onProductTap` | `Function(Product)?` | `null` | Product tap callback |
| `onQuantityChanged` | `Function(Product, int)?` | `null` | Quantity change callback |
| `cartQuantities` | `Map<String, int>?` | `null` | Current cart quantities |
| `limit` | `int` | `12` | Maximum items to load |
| `useRealTimeUpdates` | `bool` | `true` | Enable real-time updates |

## 🔧 Utilities

The implementation includes `ProductCardUtils` with helper functions:

```dart
// Calculate visible cards in viewport
int visibleCards = ProductCardUtils.calculateVisibleCards(screenWidth);

// Format prices consistently
String price = ProductCardUtils.formatPrice(199.0); // "₹199"

// Get discount information
DiscountInfo discount = ProductCardUtils.calculateDiscount(product);

// Check if image URL is valid
bool isValid = ProductCardUtils.isValidImageUrl(imageUrl);
```

## 🚨 Troubleshooting

### Common Issues

1. **Product not found errors during loading**
   - Use `ImprovedProductCard.loading()` for loading states
   - Avoid passing dummy product IDs like "loading_0"
   - Set `isLoading: true` to skip product resolution

2. **Product not found**
   - Ensure productId exists in SharedProductService
   - Check product data is properly synced

3. **Layout overflow**
   - Verify container constraints
   - Check card dimensions match screen size

4. **Performance issues**
   - Monitor cart state management efficiency
   - Use fixed dimensions for consistent performance

5. **Real-time updates not working**
   - Check RTDB connection and permissions
   - Verify repository configuration

### Debug Mode

Enable detailed logging by setting debug flags:

```dart
LoggingService.enableDebugMode = true;
```

## 🎨 Customization Examples

### Custom Horizontal Grid

```dart
SizedBox(
  height: 280.h,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: products.length,
    padding: ProductCardUtils.horizontalListPadding,
    itemBuilder: (context, index) {
      return Container(
        width: ProductCardUtils.standardCardWidth,
        margin: ProductCardUtils.getCardMargin(index, products.length),
        child: ImprovedProductCard(
          product: products[index],
          onTap: () => handleTap(products[index]),
        ),
      );
    },
  ),
)
```

### Custom Product Card Styling

```dart
ImprovedProductCard(
  product: product,
  backgroundColor: Colors.purple.shade100,
  showBrand: false,
  showWeight: false,
  enableQuantityControls: false,
  onTap: () => showProductPreview(product),
)
```

## 📈 Migration Guide

### From RTDBBestsellerGrid

```dart
// OLD
RTDBBestsellerGrid(
  onProductTap: _onProductTap,
  onQuantityChanged: _handleAddToCart,
  cartQuantities: state.cartQuantities,
  crossAxisCount: 2,
  limit: 12,
)

// NEW
HorizontalBestsellerSection(
  onProductTap: _onProductTap,
  onQuantityChanged: _handleAddToCart,
  cartQuantities: state.cartQuantities,
  limit: 12,
)
```

### From ReusableProductCard

```dart
// OLD
ReusableProductCard(
  product: product,
  finalPrice: finalPrice,
  backgroundColor: backgroundColor,
  onTap: onTap,
)

// NEW
ImprovedProductCard(
  product: product,
  finalPrice: finalPrice,
  backgroundColor: backgroundColor,
  onTap: onTap,
  onQuantityChanged: onQuantityChanged, // Added functionality
)
```

## 🎯 Best Practices

1. **Use fixed dimensions** for horizontal grids (180w x 280h)
2. **Implement proper error handling** for product resolution
3. **Pass cart quantities** for proper state management
4. **Use productId when possible** for lazy loading
5. **Enable real-time updates** for dynamic content
6. **Test on different screen sizes** to ensure responsiveness

## 📝 Notes

- The savings indicator shows flat discounts as "₹X OFF" and percentage discounts as "X% OFF"
- Cards automatically handle loading states during product resolution
- Real-time updates work with RTDB but fall back to static loading if needed
- The horizontal grid shows 2.3 cards to indicate scrollable content

---

For more detailed examples and implementation patterns, see the `ImprovedProductCardExamples` page in the examples directory.
