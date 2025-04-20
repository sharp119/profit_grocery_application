# Profit-Grocery Firebase Storage Structure for Product Images

## Firebase Storage path structure for products:

gs://profit-grocery.firebasestorage.app/products/{categoryGroupId}/{categoryItemId}/{productId}/image.png

## Example Product Image Storage Structure

* storage('gs://profit-grocery.firebasestorage.app')
  + folder('products')
    + folder('{categoryGroupId}')
      + folder('{categoryItemId}')
        + folder('{productId}')
          + file('image.png')
            ### Image Metadata
            - name: String                // "image.png"
            - size: Number                // 154,198 bytes (150.58 KB)
            - type: String                // "image/png"
            - created: Timestamp          // "Apr 20, 2025, 1:50:29 AM"
            - updated: Timestamp          // "Apr 20, 2025, 1:50:29 AM"
            - fileLocation: String        // Full path to file
            - storageLocation: String     // "gs://profit-grocery.firebasestorage.app/products/beauty_personal_care/feminine_hygiene/KJccDwFEhvMKpFlU3Kjb/image.png"
            - accessToken: String          // "10681dc7-651f-4a97-9746-b3a158b1580f"

## Complete product image storage path example:

gs://profit-grocery.firebasestorage.app/products/beauty_personal_care/feminine_hygiene/KJccDwFEhvMKpFlU3Kjb/image.png

This follows the pattern:
gs://profit-grocery.firebasestorage.app/products/{categoryGroupId}/{categoryItemId}/{productId}/image.png

The product image would be referenced in the Firestore database in the imagePath field of the product document
