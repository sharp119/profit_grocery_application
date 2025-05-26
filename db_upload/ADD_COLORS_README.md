# 🎨 Item Background Color Enhancement Script

This script adds `itemBackgroundColor` parameter to each product based on their category group.

## What it does

Analyzes each product's `path` field to determine their category group and adds the corresponding `itemBackgroundColor` value.

## Category Color Mapping

Based on your Firestore categories:

| Category | itemBackgroundColor |
|----------|-------------------|
| **snacks_drinks** | `4292998654` |
| **grocery_kitchen** | `4292998633` |  
| **fruits_vegetables** | `4293457385` |
| **bakeries_biscuits** | `4294962355` |

## Usage

```bash
npm run add-item-colors
```

## Smart File Detection

The script automatically finds and uses:
1. **Latest enhanced file** (`enhanced_products_*.json`) - if available
2. **Original flattened file** (`flattened_products.json`) - as fallback

## Example Enhancement

**Before:**
```json
{
  "dynamic_product_info": {
    "9LHIJiPrwOcVSMLlN3Y6": {
      "hasDiscount": true,
      "inStock": true,
      "path": "bakeries_biscuits/bakery_snacks",
      "name": "Chocolate Chip Cookies",
      "brand": "Cookie Master",
      "weight": "250g"
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
      "inStock": true,
      "path": "bakeries_biscuits/bakery_snacks",
      "name": "Chocolate Chip Cookies", 
      "brand": "Cookie Master",
      "weight": "250g",
      "itemBackgroundColor": 4294962355
    }
  }
}
```

## How it Works

1. **Detects** the most recent products file
2. **Extracts** category group from each product's `path` field
3. **Maps** category group to corresponding `itemBackgroundColor`
4. **Adds** the color value to each product
5. **Saves** enhanced data with timestamp

## Output Files

Creates timestamped files:
- `products_with_colors_YYYY-MM-DDTHH-mm-ss-sssZ.json` - Enhanced products
- `color_enhancement_summary_YYYY-MM-DDTHH-mm-ss-sssZ.txt` - Summary report

## Path Format

Products must have a `path` field in format: `{categoryGroup}/{categoryItem}`

Examples:
- `"bakeries_biscuits/cookies"` → `itemBackgroundColor: 4294962355`
- `"snacks_drinks/chips_namkeen"` → `itemBackgroundColor: 4292998654`
- `"fruits_vegetables/fresh_fruits"` → `itemBackgroundColor: 4293457385`
- `"grocery_kitchen/atta_rice_dal"` → `itemBackgroundColor: 4292998633`

## Error Handling

- ✅ **Missing path field**: Logs warning, skips product
- ✅ **Unknown category**: Logs warning, reports in summary  
- ✅ **Invalid path format**: Graceful handling with error reporting
- ✅ **File not found**: Clear error message with suggestions

## Integration with Enhancement Workflow

This script works seamlessly with the product enhancement workflow:

```bash
# Step 1: Enhance with name, brand, weight, tags
npm run enhance-products

# Step 2: Add category background colors  
npm run add-item-colors
```

Or can be run standalone on the original flattened products file.

## Color Values

The color values are 32-bit integers representing ARGB colors:
- `4292998654` = Light blue-gray
- `4292998633` = Similar blue-gray variant  
- `4293457385` = Green-tinted
- `4294962355` = Light orange/beige

These match exactly with your Firestore category configuration.
