# Profit-Grocery Firestore Schema - Categories Structure
## Hierarchy: categories -> categoryGroups -> items -> categoryItems

### Root Collection: categories
collection('categories')

#### Document: categoryGroup (e.g., "bakeries_biscuits")
document('{categoryGroupId}')
##### Category Group Details
{
  backgroundColor: Number,       // 4280163870
  id: String,                    // "bakeries_biscuits"
  itemBackgroundColor: Number,   // 4294962355
  title: String                  // "Bakery & Biscuits"
}

##### Subcollection: items
collection('items')

###### Document: categoryItem (e.g., "bakery_snacks")
document('{categoryItemId}')
####### Category Item Details
{
  description: String,           // null
  id: String,                    // "bakery_snacks"
  imagePath: String,             // URL to Firebase Storage
  label: String                  // "Bakery Snacks"
}

