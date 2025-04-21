# Profit Grocery Application - Discount and Bestseller Collections

This README explains how to create and manage the new discount and bestseller collections.

## Overview

The application uses two important collections:

1. **Discounts Collection**: Contains products with discounts
   - Each document has its ID same as the productID
   - Fields include: active, discountType, discountValue, endTimestamp, productID, startTimestamp
   - Discount types: 'flat' (for products > 200 Rs) and 'percentage' (for any product)
   - Total count: 120 products

2. **Bestsellers Collection**: Lists top products
   - Each document has its ID same as the productID
   - Field: rank (position in bestsellers list)
   - Includes both discounted and non-discounted products
   - 12 products are from discount collection (6 with flat discount, 6 with percentage discount)

## Scripts

Three new scripts have been added to manage these collections:

1. `create_new_discounts.js` - Creates only the discount collection
2. `create_new_bestsellers.js` - Creates both discount and bestseller collections
3. `create_new_collections.js` - An alias for create_new_bestsellers.js that creates both collections

## How to Use

### Prerequisites

1. Make sure your Firebase configuration is set up in the `.env` file
2. Make sure you've installed all dependencies with `npm install`

### Creating Both Collections (Recommended)

To create both collections at once:

```bash
npm run create-new-collections
```

This will:
1. Clear existing discounts and bestsellers collections
2. Create 120 discounts (mix of flat and percentage)
3. Create bestsellers with 12 discounted products (6 flat, 6 percentage)

### Creating Individual Collections

To create only the discounts collection:

```bash
npm run create-new-discounts
```

To create only the bestsellers collection (requires existing discounts):

```bash
npm run create-new-bestsellers
```

## Explanation of Fields

### Discounts Collection
- `active` (boolean): Whether the discount is active
- `discountType` (string): Either "flat" or "percentage"
- `discountValue` (number): The amount of discount
- `startTimestamp` (timestamp): When the discount begins
- `endTimestamp` (timestamp): When the discount ends
- `productID` (string): ID of the product from the products collection

### Bestsellers Collection
- `rank` (number): Position in the bestsellers list (1 being the top)

## Technical Notes

- The scripts clean up existing collections before creating new ones
- The bestseller script ensures a good mix of products with both types of discounts
- Flat discounts are only applied to products costing more than 200 Rs 