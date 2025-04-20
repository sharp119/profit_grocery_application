# Profit-Grocery Firebase Storage Structure
## This shows how images are stored in Firebase Storage alongside the Firestore database

## Firebase Storage follows a similar hierarchical path structure to Firestore
### Path structure: `gs://profit-grocery.firebasestorage.app/categories/{categoryGroupId}/{categoryItemId}/{imageFile}`

## Example Image Storage Structure
### `storage('gs://profit-grocery.firebasestorage.app')`
#### `folder('categories')`
##### `folder('{categoryGroupId}')`
###### `folder('{categoryItemId}')`
####### `file('category_image.png')`
######## Image Metadata
######### `name`: `String`                // "category_image.png"
######### `size`: `Number`                // 163,564 bytes (159.73 KB)
######### `type`: `String`                // "image/png"
######### `created`: `Timestamp`          // "Apr 17, 2025, 6:40:09 AM"
######### `updated`: `Timestamp`          // "Apr 17, 2025, 6:40:09 AM"
######### `fileLocation`: `String`        // Full path to file
######### `storageLocation`: `String`     // "gs://profit-grocery.firebasestorage.app/categories/bakeries_biscuits/bakery_snacks/category_image.png"
######### `accessToken`: `String`          // "48f929b8-02b1-4c86-8ee3-30ec1795a9bb"

## Similar structure is used for product images:
### `gs://profit-grocery.firebasestorage.app/products/{categoryGroupId}/{categoryItemId}/{productId}/product_image.png`

## Complete storage path examples:
### 1. Category image: 
###    `gs://profit-grocery.firebasestorage.app/categories/bakeries_biscuits/bakery_snacks/category_image.png`
### 
### 2. Product image (example): 
###    `gs://profit-grocery.firebasestorage.app/products/fruits_vegetables/exotic_vegetables/fjVKtTrytyzem9yK5qVK/product_image.png`
