# Profit-Grocery Firestore Schema - Bestsellers Collection

## Root Collection: bestsellers
collection('bestsellers')

  ## Document: product ID (e.g., "0hDdYOX7FB5UDUs1Gbe6")
  document('{productId}')

    ### Bestseller Details
    {
      discountType: String,      # "percentage"
      discountValue: Number,     # 10
      rank: Number               # 19
    }

## Note:
- The document ID in the bestsellers collection is the same as the product ID it refers to in the products collection
- This allows for efficient lookup when checking if a product is a bestseller
- The `rank` field indicates the importance or position of the product in bestseller listings
- Lower rank numbers typically indicate higher bestseller status
- Bestsellers may have their own discount values which could be different from the main discounts collection
- The `discountType` field can be either "percentage" or "flat" to indicate the type of discount
- For percentage discounts, the `discountValue` field contains the percentage off (e.g., 10 means 10% off)
- For flat discounts, the `discountValue` field contains the amount to subtract from the original price

## Example path to a specific bestseller:
# bestsellers/0hDdYOX7FB5UDUs1Gbe6