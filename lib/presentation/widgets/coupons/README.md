# ProfitGrocery Coupon System

## Overview

The coupon system in ProfitGrocery allows users to apply various types of promotional offers to their shopping cart. The system supports different coupon types, including percentage discounts, fixed amount discounts, free products, free delivery, and conditional offers (like buy X get Y).

## Coupon Types

1. **Percentage Discount** - Apply a percentage discount on the total order value
2. **Fixed Amount** - Apply a flat discount amount on the total order value
3. **Free Product** - Add a free product to the cart when conditions are met
4. **Free Delivery** - Remove delivery charges from the order
5. **Conditional** - Special offers like "Buy 2 Get 1 Free" or "Buy Product A and get discount on Product B"

## Key Components

### 1. SampleCoupon Class

Located in `lib/data/samples/sample_coupons.dart`, this class defines the structure of coupon data including:
- Basic information (ID, code, type, value)
- Display information (title, description, backgroundColor, imageAsset)
- Validity conditions (startDate, endDate, minPurchase, usageLimit)
- Applicability (applicableProductIds, applicableCategories)
- Type-specific fields (freeProductId, conditions)

### 2. CouponCard Widget

Located in `lib/presentation/widgets/coupons/coupon_card.dart`, this widget displays a coupon in the list with:
- Coupon code and copy function
- Basic information about the offer
- "View Details" option that opens the detailed modal

### 3. CouponDetailModal Widget

Located in `lib/presentation/widgets/coupons/coupon_detail_modal.dart`, this bottom sheet modal shows detailed information about a coupon:
- Complete coupon information with icons and visuals
- Type-specific details (e.g., free product image, conditional requirements)
- Terms and validity information
- Apply button

### 4. CouponPage

Located in `lib/presentation/pages/coupon/coupon_page.dart`, this is the main screen for coupon management:
- Lists all available coupons
- Allows manual coupon code entry
- Handles deep link coupons from WhatsApp marketing
- Shows highlighted special offers

## Integration Points

The coupon system integrates with:

1. **Cart System** - To apply discounts to the cart total
2. **Checkout Flow** - To display applied coupon information
3. **WhatsApp Marketing** - Through deep links that open the app with a pre-populated coupon
4. **Firestore** - To store and retrieve coupon data (currently using sample data)
5. **Remote Config** - For dynamic coupon management (not implemented yet)

## Implementation Notes

- Currently, the system uses sample data from `sample_coupons.dart`
- In production, coupons should be fetched from Firestore
- Deep link functionality is mocked in the current implementation
- The UI follows the app's "Dense Grid UI" design pattern with premium black and gold accents

## Future Enhancements

1. Connect to Firebase for real-time coupon data
2. Implement proper deep link handling for WhatsApp marketing
3. Add admin panel for coupon management
4. Implement personalized coupon recommendations
5. Add coupon sharing functionality
