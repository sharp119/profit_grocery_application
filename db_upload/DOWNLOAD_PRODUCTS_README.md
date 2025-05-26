# Firestore Products Download Script

This script downloads the entire product collection from Firestore and saves it as a structured JSON file.

## Overview

The script traverses the complete Firestore products collection structure:
```
/products/{categoryGroup}/items/{categoryItem}/products/{productDoc}
```

And exports it to a well-organized JSON file with metadata.

## Features

- ✅ Downloads ALL products from ALL category groups
- ✅ Maintains the hierarchical structure (categoryGroup → categoryItem → products)
- ✅ Includes comprehensive metadata (export date, totals, duration, etc.)
- ✅ Handles Firestore timestamp conversion to ISO strings
- ✅ Progress tracking with detailed console output
- ✅ Error handling with graceful fallbacks
- ✅ Rate limiting to avoid overwhelming Firestore
- ✅ Generates both JSON export and human-readable summary

## Prerequisites

1. **Environment Setup**: Make sure you have a `.env` file with your Firebase configuration:
   ```
   FIREBASE_API_KEY=your_api_key_here
   FIREBASE_AUTH_DOMAIN=your_auth_domain_here
   FIREBASE_DATABASE_URL=your_database_url_here
   FIREBASE_PROJECT_ID=your_project_id_here
   FIREBASE_STORAGE_BUCKET=your_storage_bucket_here
   FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id_here
   FIREBASE_APP_ID=your_app_id_here
   FIREBASE_MEASUREMENT_ID=your_measurement_id_here
   ```

2. **Dependencies**: The script uses existing project dependencies (Firebase v10, dotenv)

## Usage

### Option 1: Using npm script (Recommended)
```bash
npm run download-all-products
```

### Option 2: Direct execution
```bash
node download_all_products.js
```

## Output Files

The script generates two files with timestamps:

1. **JSON Export** (`firestore_products_export_YYYY-MM-DDTHH-mm-ss-sssZ.json`):
   - Complete product data in structured JSON format
   - Includes metadata about the export
   - Ready for import/analysis

2. **Summary Report** (`firestore_products_summary_YYYY-MM-DDTHH-mm-ss-sssZ.txt`):
   - Human-readable summary of the export
   - Breakdown by category groups and items
   - Export statistics and timing

## JSON Structure

```json
{
  "metadata": {
    "exportDate": "2025-05-26T10:30:00.000Z",
    "totalCategoryGroups": 6,
    "totalCategoryItems": 42,
    "totalProducts": 168,
    "exportDurationMs": 5432,
    "firebaseProject": "your-project-id"
  },
  "products": {
    "bakeries_biscuits": {
      "bakery_snacks": [
        {
          "id": "doc123",
          "name": "Butter Garlic Bread Sticks",
          "price": 60,
          "inStock": true,
          "createdAt": "2025-05-26T10:00:00.000Z",
          "updatedAt": "2025-05-26T10:00:00.000Z",
          // ... other product fields
        }
      ],
      "cookies": [
        // ... more products
      ]
    },
    "dairy_eggs": {
      // ... more category items
    }
    // ... more category groups
  }
}
```

## Performance Notes

- The script includes rate limiting (100ms between category items, 200ms between category groups)
- Progress is shown in real-time with emojis and clear formatting
- Memory efficient - processes one category at a time
- Typical export time: 5-30 seconds depending on collection size

## Error Handling

- Individual product failures don't stop the entire export
- Category group failures are logged but don't crash the script
- Detailed error messages with stack traces for debugging
- Graceful handling of missing collections or documents

## Use Cases

- **Backup**: Create regular backups of your product catalog
- **Analysis**: Import into spreadsheets or analytics tools
- **Migration**: Move products between environments
- **Development**: Seed test databases with production data
- **Monitoring**: Track product catalog changes over time

## Troubleshooting

### Common Issues:

1. **Permission Denied**: Ensure your Firebase config has read access to the products collection
2. **Network Timeouts**: The script includes retry logic, but very large collections might need adjustment
3. **File Write Errors**: Check disk space and write permissions in the current directory

### Debug Mode:
The script provides verbose console output showing:
- Category groups being processed
- Individual category items
- Product counts at each level
- Any errors encountered

## Related Scripts

- `add_products_*.js` - Scripts that populate the products collection
- `firestore_export.js` - Alternative admin SDK export (categories only)
- `verify_*.js` - Scripts that validate product data integrity
