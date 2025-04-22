# Profit-Grocery Firestore Schema - Discounts Collection

## Root Collection: discounts
collection('discounts')

  ## Document: product ID (e.g., "0TP7NjIaHJ1dQkjBkGqg")
  document('{productId}')

    ### Discount Details
    {
      active: Boolean,           # true
      discountType: String,      # "percentage" or "flat"
      discountValue: Number,     # 14 (percentage) or amount (flat)
      endTimestamp: Timestamp,   # April 24, 2025 at 3:21:28 AM UTC+5:30
      productID: String,         # "0TP7NjIaHJ1dQkjBkGqg"
      startTimestamp: Timestamp  # April 22, 2025 at 3:21:28 AM UTC+5:30
    }

## Note:
- The document ID in the discounts collection is the same as the product ID it refers to in the products collection
- This allows for efficient lookup when checking if a product has a discount
- The `discountType` field can be either "percentage" or "flat" to indicate the type of discount
- For percentage discounts, the `discountValue` field contains the percentage off (e.g., 14 means 14% off)
- For flat discounts, the `discountValue` field contains the amount to subtract from the original price

## Example path to a specific discount:
# discounts/0TP7NjIaHJ1dQkjBkGqg