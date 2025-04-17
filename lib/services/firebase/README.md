# Firebase Services

This directory contains all Firebase-related services for the ProfitGrocery application.

## Services Overview

- **FirestoreService**: Handles all interactions with Cloud Firestore.
- **FirebaseStorageService**: Manages file uploads and downloads with Firebase Storage.
- **DataSetupService**: Handles initialization of data in Firebase (categories, products, etc.).
- **DataMigrationService**: Provides functionality to migrate data between different Firebase structures.
- **MigrationRunner**: Utility to run migrations with UI feedback.

## Data Structure

### Categories and Products Structure

The application uses a nested data structure for categories and products:

```
/categories/{categoryGroupId}/                 # Category Group (e.g., "fruits_vegetables")
    - id: string
    - title: string
    - backgroundColor: number
    - itemBackgroundColor: number
    
    /items/{categoryItemId}/                   # Category Item (e.g., "fresh_fruits")
        - id: string
        - label: string
        - imagePath: string
        - description: string

/products/{categoryGroupId}/                   # Products organized by Category Group
    /{categoryItemId}/                         # Products organized by Category Item
        /products/                             # Products collection
            /items/                            # Items collection
                /{productId}/                  # Individual Product
                    - id: string
                    - name: string
                    - description: string
                    - price: number
                    - mrp: number
                    - inStock: boolean
                    - ...other product fields
```

For faster queries, products are also stored in a flat collection:

```
/products/{productId}/
    - id: string
    - name: string
    - description: string
    - price: number
    - mrp: number
    - inStock: boolean
    - categoryId: string
    - subcategoryId: string
    - ...other product fields
```

### Storage Structure

Images are stored in Firebase Storage with the following path structure:

```
/categories/{categoryGroupId}/{categoryItemId}/category_image.png
/products/{categoryGroupId}/{categoryItemId}/{productId}/product_image.png
```

This structure ensures that:
1. Category images are organized by category group and item
2. Product images are organized in the same hierarchy as product data
3. All paths follow a consistent pattern for easy retrieval

## Migration

The application includes tools to migrate between different data structures:

1. **Database Migration**: Migrates data between Realtime Database and Firestore.
2. **Product Structure Migration**: Reorganizes products to be properly nested under category items.

### Running a Migration

Migrations can be run from the admin interface at:

```
Admin > Database Migration
```

There are two migration options:

1. **Realtime Database to Firestore**: Migrates all data from RTDB to Firestore
2. **Product Structure Migration**: Reorganizes existing products to the correct nested structure

## Usage

Example code to store a product:

```dart
final FirestoreService firestoreService = FirestoreService();
final FirebaseStorageService storageService = FirebaseStorageService();

// Upload a product image
final String imageUrl = await storageService.uploadRandomProductImage(
  productId: 'product123',
  categoryId: 'fruits_vegetables',
  subcategoryId: 'fresh_fruits',
);

// Create a product model
final product = ProductModel(
  id: 'product123',
  name: 'Organic Apple',
  image: imageUrl,
  description: 'Fresh organic apples',
  price: 99.0,
  mrp: 120.0,
  inStock: true,
  categoryId: 'fruits_vegetables',
  subcategoryId: 'fresh_fruits',
  tags: ['fruits', 'organic'],
  isFeatured: true,
);

// Add the product
await firestoreService.addProduct(product);
```