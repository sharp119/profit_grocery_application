# 🔧 Product Enhancement Script

This script enhances your flattened products JSON by adding product details from the Firestore export.

## What it does

Takes your `flattened_products.json` file and adds **exactly 4 fields** to each product in `dynamic_product_info`:

- ✅ **`name`** - Product name
- ✅ **`brand`** - Brand name  
- ✅ **`weight`** - Product weight/size
- ✅ **`tags`** - Product tags array

## Usage

```bash
npm run enhance-products
```

## Input Files

The script expects these files to exist:
- `F:\Soup\projects\profit_grocery_application\flattened_products.json`
- `F:\Soup\projects\profit_grocery_application\db_upload\firestore_products_export_2025-05-26T15-57-13-577Z.json`

## Output Files

Creates timestamped files:
- `enhanced_products_YYYY-MM-DDTHH-mm-ss-sssZ.json` - Your enhanced data
- `enhancement_summary_YYYY-MM-DDTHH-mm-ss-sssZ.txt` - Summary report

## Example Enhancement

**Before (from flattened_products.json):**
```json
{
  "dynamic_product_info": {
    "9LHIJiPrwOcVSMLlN3Y6": {
      "hasDiscount": true,
      "inStock": true,
      "quantity": 15,
      "mrp": 90,
      "discount": {
        "start": 1748269547,
        "end": 1750861547,
        "isActive": true,
        "type": "flat",
        "value": 32.4
      },
      "path": "bakeries_biscuits/bakery_snacks"
    }
  }
}
```

**After enhancement:**
```json
{
  "dynamic_product_info": {
    "9LHIJiPrwOcVSMLlN3Y6": {
      "hasDiscount": true,
      "inStock": true,
      "quantity": 15,
      "mrp": 90,
      "discount": {
        "start": 1748269547,
        "end": 1750861547,
        "isActive": true,
        "type": "flat",
        "value": 32.4
      },
      "path": "bakeries_biscuits/bakery_snacks",
      "name": "Chocolate Chip Cookies",
      "brand": "Cookie Master",
      "weight": "250g",
      "tags": []
    }
  }
}
```

## Key Features

- 🎯 **Strict Enhancement**: Only adds the 4 requested fields, nothing else
- 🔄 **Preserves Structure**: Keeps your original JSON structure intact
- 📊 **Progress Tracking**: Shows real-time progress and statistics  
- ⚠️ **Error Handling**: Reports products that couldn't be matched
- 📄 **Summary Report**: Detailed report of enhancement results
- ⏱️ **Timestamped Output**: Prevents overwriting previous enhancements

## How it Works

1. **Loads** both your flattened products and Firestore export
2. **Creates** a lookup map from Firestore products by ID
3. **Matches** each product in `dynamic_product_info` with Firestore data
4. **Adds** only the 4 requested fields (name, brand, weight, tags)
5. **Saves** enhanced data with timestamp
6. **Generates** summary report

The script is designed to be safe and non-destructive - your original files remain unchanged.
