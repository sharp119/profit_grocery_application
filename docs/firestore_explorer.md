# Firestore Data Explorer

This document explains how to use the Firestore Data Explorer feature added to the ProfitGrocery application.

## Overview

The Firestore Data Explorer is a tool that allows you to browse and explore the data stored in Firestore directly from the app. It shows the hierarchical structure of categories and products, matching the Firestore database structure shown in the provided images.

## Features

1. **Browse Categories**: View all categories in a collapsible tree view
2. **View Products**: Select a category to view all products in that category
3. **Product Details**: Expand product items to see detailed information including:
   - Name, price, description
   - Brand, SKU, weight
   - Nutritional information
   - Ingredients
   - Images
4. **Fetch All Products**: Load all products from all categories (may take time for large databases)

## How to Use

1. Open the ProfitGrocery app
2. Go to the Home screen
3. Scroll down to the bottom of the page to the "Developer Testing" section
4. Tap the "Explore Firestore Data" button
5. The explorer will open as a bottom sheet with two main sections:
   - Categories
   - Products

6. To view products in a specific category:
   - Expand a category group by tapping on it
   - Tap on any category item to load its products
   - The products section will update to show the products in that category

7. To view details about a product:
   - Expand a product by tapping on it
   - All fields from the Firestore document will be displayed

8. To load all products:
   - Tap the "Fetch All Products" button at the bottom of the sheet
   - This may take some time depending on the number of products

## Technical Implementation

The feature was implemented with the following components:

1. **FirestoreProductRepository**: A new repository for fetching products from Firestore following the nested collection structure shown in the Firestore database.

2. **Product Entity and Model Updates**: Added additional fields to the Product entity to match the Firestore document structure, including:
   - nutritionalInfo
   - ingredients
   - sku
   - productType
   - quantity
   - categoryGroup

3. **UI Implementation**: A modal bottom sheet with a draggable, scrollable container that shows both categories and products.

## Firestore Database Structure

The code is designed to work with the following Firestore structure:

```
products/
  ├── bakeries_biscuits/
  │   └── items/
  │       ├── bakery_snacks/
  │       │   └── products/
  │       │       ├── product1
  │       │       ├── product2
  │       │       └── ...
  │       ├── buns_pavs/
  │       │   └── products/
  │       │       └── ...
  │       └── ...
  ├── beauty_personal_care/
  └── ...
```

Each product document contains fields like:
- name
- description
- price
- imagePath
- inStock
- brand
- ingredients
- nutritionalInfo
- sku
- weight
- productType
- quantity

## Development Notes

- The product fetching is done on-demand to keep the app responsive
- For large datasets, consider implementing pagination in the future
- The UI is built with a StatefulBuilder to allow for interactive updates
- Error handling is implemented to gracefully handle failures