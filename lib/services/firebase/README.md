# Firebase Data Setup

This module provides functionality to set up products and categories in Firebase Firestore and Storage.

## Overview

The implementation includes:

1. **Firebase Storage Service** (`firebase_storage_service.dart`)
   - Handles uploading images from assets to Firebase Storage
   - Creates organized folder structure for products and categories
   - Returns download URLs for the uploaded images

2. **Firestore Service** (`firestore_service.dart`)
   - Manages database operations for products and categories
   - Creates proper document structure in Firestore
   - Handles CRUD operations for products and categories

3. **Data Setup Service** (`data_setup_service.dart`)
   - Orchestrates the setup process
   - Creates all category groups and items
   - Creates sample products for each category
   - Updates image paths with Firebase Storage URLs
   - Provides progress tracking and callbacks

4. **UI Components**
   - `SetupDataButton` - A button for the home screen to trigger the setup process
   - `DataSetupDialog` - A dialog showing setup progress and results

## Usage

The setup process is triggered by the "Initialize Firebase Data" button on the home screen. This button is only visible to admin users.

When clicked, it will:

1. Show a confirmation dialog
2. Start the setup process
3. Display progress in a dialog
4. Notify completion or failure

## Data Structure

### Firestore Collections

- **categories/**
  - `{categoryGroupId}/`
    - id, title, backgroundColor, itemBackgroundColor
    - **items/**
      - `{categoryItemId}/`
        - id, label, imagePath, description

- **products/**
  - `{productId}/`
    - id, name, image, description, price, mrp, inStock, categoryId, subcategoryId, tags, isFeatured, isActive, weight, brand, rating, reviewCount

### Firebase Storage Structure

- **categories/**
  - `{categoryGroupId}/`
    - `{categoryItemId}/`
      - category_image.png

- **products/**
  - `{categoryId}/`
    - `{productId}/`
      - product_image.png

## Notes

- The setup process should only be run once during initial app setup.
- It creates 6 sample products for each category item.
- All category groups from the `CategoryGroups` class are included.
- Random product images are selected from the assets/products folder.
- Category images are taken from the assets/subcategories folder based on the paths in the CategoryItem model.
