# Profit-Grocery Firestore Schema - Key Components
# Hierarchy: products -> categoryGroups -> items -> categoryItems -> products -> productIDs -> productDetails

## Root Collection: products
collection('products')

  ## Document: categoryGroup (e.g., "bakeries_biscuits")
  document('{categoryGroupId}')

    ## Subcollection: items
    collection('items')

      ## Document: categoryItem (e.g., "bakery_snacks")
      document('{categoryItemId}')

        ## Subcollection: products
        collection('products')

          ## Document: product (with auto-generated ID like "9LHtJiPrw0cVSMLlN3Y6")
          document('{productId}')

            ### Product Details
            {
              brand: String,              # "Cookie Master"
              categoryGroup: String,      # "bakeries_biscuits"
              categoryItem: String,       # "bakery_snacks"
              createdAt: Timestamp,       # April 20, 2025 at 1:25:53 AM UTC+5:30
              description: String,        # "Soft and chewy cookies loaded with premium chocolate chips"
              hasDiscount: Boolean,       # false
              imagePath: String,          # URL to Firebase Storage
              inStock: Boolean,           # true
              ingredients: String,        # "Refined flour, chocolate chips, butter, sugar, eggs"
              name: String,               # "Chocolate Chip Cookies"
              nutritionalInfo: String,    # "Calories: 200 per serving, Protein: 3g, Carbs: 30g, Fat: 8g"
              price: Number,              # 120
              productType: String,        # "Bakery Snacks"
              quantity: Number,           # 15
              sku: String,                # "BKRY002"
              updatedAt: Timestamp,       # April 20, 2025 at 1:25:53 AM UTC+5:30
              weight: String              # "250g"
            }

# Example path to a specific product:
# products/bakeries_biscuits/items/bakery_snacks/products/9LHtJiPrw0cVSMLlN3Y6

