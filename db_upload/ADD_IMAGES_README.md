# 🖼️ Image Path Enhancement Script

This script adds `imagePath` to each product by extracting the Firebase Storage URLs from the Firestore export.

## What it does

Matches products by ID and adds the corresponding `imagePath` field containing the full Firebase Storage URL for the product image.

## Usage

```bash
npm run add-image-paths
```

## Smart File Detection

The script automatically finds and uses the most recent products file:
1. **Latest enhanced file** (`products_with_colors_*.json`) - if available
2. **Previous enhanced file** (`enhanced_products_*.json`) - if available  
3. **Original flattened file** (`flattened_products.json`) - as fallback

## Source Data

Reads image paths from:
`F:\Soup\projects\profit_grocery_application\db_upload\firestore_products_export_2025-05-26T15-57-13-577Z.json`

## Example Enhancement

**Before:**
```json
{
  "dynamic_product_info": {
    "9LHIJiPrwOcVSMLlN3Y6": {
      "hasDiscount": true,
      "name": "Chocolate Chip Cookies",
      "brand": "Cookie Master",
      "weight": "250g",
      "itemBackgroundColor": 4294962355
    }
  }
}
```

**After:**
```json
{
  "dynamic_product_info": {
    "9LHIJiPrwOcVSMLlN3Y6": {
      "hasDiscount": true,
      "name": "Chocolate Chip Cookies",
      "brand": "Cookie Master", 
      "weight": "250g",
      "itemBackgroundColor": 4294962355,
      "imagePath": "https://firebasestorage.googleapis.com/v0/b/profit-grocery.firebasestorage.app/o/products%2Fbakeries_biscuits%2Fbakery_snacks%2F9LHIJiPrwOcVSMLlN3Y6%2Fimage.png?alt=media&token=274e09b9-222a-4e3b-9453-3cb0ef1ff2a4"
    }
  }
}
```

## Image URL Format

The Firebase Storage URLs follow this pattern:
```
https://firebasestorage.googleapis.com/v0/b/profit-grocery.firebasestorage.app/o/products%2F{categoryGroup}%2F{categoryItem}%2F{productId}%2Fimage.png?alt=media&token={accessToken}
```

Examples:
- `products%2Fbakeries_biscuits%2Fcookies%2F{productId}%2Fimage.png`
- `products%2Fsnacks_drinks%2Fchips_namkeen%2F{productId}%2Fimage.png`
- `products%2Ffruits_vegetables%2Ffresh_fruits%2F{productId}%2Fimage.png`

## How it Works

1. **Loads** the Firestore export file
2. **Creates** a lookup map of productId → imagePath
3. **Finds** the most recent products file
4. **Matches** each product by ID
5. **Adds** the `imagePath` field to each product
6. **Saves** enhanced data with timestamp

## Output Files

Creates timestamped files:
- `products_with_images_YYYY-MM-DDTHH-mm-ss-sssZ.json` - Enhanced products
- `image_enhancement_summary_YYYY-MM-DDTHH-mm-ss-sssZ.txt` - Summary report

## Error Handling

- ✅ **Missing Firestore export**: Clear error with file path
- ✅ **Product not found**: Logs warning, reports in summary  
- ✅ **No image path**: Graceful handling for products without images
- ✅ **File not found**: Auto-detects available files with fallback

## Integration with Enhancement Workflow

Perfect for the complete enhancement pipeline:

```bash
# Step 1: Enhance with name, brand, weight, tags
npm run enhance-products

# Step 2: Add category background colors  
npm run add-item-colors

# Step 3: Add product image paths
npm run add-image-paths
```

## Expected Success Rate

Should achieve ~95-100% success rate since the Firestore export contains products with their image paths. Any missing images are typically products that haven't had images uploaded yet.

## Image Access

The Firebase Storage URLs include access tokens and are directly usable in:
- ✅ Web applications
- ✅ Mobile apps  
- ✅ API responses
- ✅ Image display components

No additional authentication required as the tokens provide public access to the product images.

## File Size Impact

Adding image paths typically increases the JSON file size by ~15-20% due to the full Firebase Storage URLs, but provides immediate access to all product images.
