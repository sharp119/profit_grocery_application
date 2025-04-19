# Firestore Categories Explorer & Products Structure Creator

This project contains scripts to explore and populate your Firestore collections.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

## Available Scripts

### 1. Explore Categories Structure
```bash
npm run explore
```
This will create a file called `categories_structure.txt` containing the entire structure of your categories collection.

### 2. Create Products Structure
```bash
npm run create-products
```
This will create a new `products` collection with the exact same structure as `categories`, but with empty documents (no data).

### 3. Preview Products Structure (Dry Run)
```bash
npm run preview-products
```
This will show you what would be created without actually making any changes to your database.

### 4. Add Bakery Products
```bash
npm run add-bakery-products
```
This will populate the `bakeries_biscuits` category with realistic product data including:
- Product names and descriptions
- Prices, quantities, weights
- Stock status, SKUs, brands
- Nutritional information
- Properly formatted image paths

### 5. Cleanup Bakery Products (if needed)
```bash
npm run cleanup-bakery-products
```
### 6. Update Image Paths (if needed)
```bash
npm run update-image-paths
```
This will update existing products to include the complete Firebase Storage URL (`gs://`) in their image paths.

### 7. Add Beauty Products
```bash
npm run add-beauty-products
```
This will populate the `beauty_personal_care` category with realistic product data.

### 8. Cleanup Beauty Products (if needed)
```bash
npm run cleanup-beauty-products
```
### 9. Add Dairy Products
```bash
npm run add-dairy-products
```
This will populate the `dairy_bread` category with realistic product data.

### 10. Cleanup Dairy Products (if needed)
```bash
npm run cleanup-dairy-products
```
This will remove all products from the `dairy_bread` category in case you need to start fresh.

### 11. Add Fruits & Vegetables Products
```bash
npm run add-fruits-vegetables-products
```
This will populate the `fruits_vegetables` category with realistic product data.

### 12. Cleanup Fruits & Vegetables Products (if needed)
```bash
npm run cleanup-fruits-vegetables-products
```
### 13. Add Grocery & Kitchen Products
```bash
npm run add-grocery-kitchen-products
```
This will populate the `grocery_kitchen` category with realistic product data.

### 14. Cleanup Grocery & Kitchen Products (if needed)
```bash
npm run cleanup-grocery-kitchen-products
```
This will remove all products from the `grocery_kitchen` category in case you need to start fresh.

### 15. Add Snacks & Drinks Products
```bash
npm run add-snacks-drinks-products
```
This will populate the `snacks_drinks` category with realistic product data.

### 16. Cleanup Snacks & Drinks Products (if needed)
```bash
npm run cleanup-snacks-drinks-products
```
This will remove all products from the `snacks_drinks` category in case you need to start fresh.

### 17. Add All Products At Once
```bash
npm run add-all-products
```
This will run all product creation scripts sequentially to populate all categories.

### 18. Upload Product Images
```bash
npm run upload-product-images
```
This will:
- Scan the `products` folder for available images
- Randomly select images for each product
- Upload them to Firebase Storage with the correct path structure
- Sync perfectly with the product data in Firestore

To upload images for a specific category:
```bash
npm run upload-product-images-for-category bakeries_biscuits
```

### 19. Verify Product Images
```bash
npm run verify-product-images
```
This will check all product image paths in Firestore and verify that corresponding images exist in Firebase Storage.

### Important Note on Image Upload
Make sure you have a `products` folder in your project directory containing the images you want to use. The script will randomly select from these images and upload them to match each product's image path in Firestore.

Each product includes:
- `name`: Product name
- `description`: Detailed description
- `inStock`: Boolean indicating availability
- `price`: Price in your local currency
- `quantity`: Available quantity
- `weight`: Product weight
- `brand`: Brand name
- `ingredients`: List of ingredients
- `nutritionalInfo`: Nutritional information
- `sku`: Stock keeping unit
- `productType`: Type of product
- `imagePath`: Path to product image (automatically generated)

## Image Path Structure

Product images are organized in Firebase Storage with the following structure:
```
gs://profit-grocery.firebasestorage.app/products/[categoryGroup]/[categoryItem]/[productID]/image.png
```

This structure is automatically generated when products are added.
