# Understanding SharedPreferences in Android
_Exported on 5/17/2025 at 23:49:09 GMT+5:30 from Cursor (0.50.4)_

---

**User**

sharedpreferences are temporary right ?? its used to just share values accors different pages of the same app for current time ??

---

**Cursor**

Let me clarify how **SharedPreferences** work, especially in the context of Android development (where this term is most commonly used):

### What is SharedPreferences?
- **SharedPreferences** is a way to store simple key-value pairs of primitive data types (like strings, ints, booleans) in Android apps.
- It is used for storing small amounts of data, such as user settings, login status, or app preferences.

### Are SharedPreferences Temporary?
- **No, SharedPreferences are not temporary.**
- Data stored in SharedPreferences persists even after the app is closed or the device is restarted.
- The data remains until you explicitly remove it or uninstall the app.

### What is it used for?
- It is used to store values that you want to keep across different sessions of the app.
- You can access these values from different pages (activities/fragments) within the same app.
- It is **not** just for sharing values for the current time or session; it is for persistent storage.

### Example Use Cases
- Remembering if a user is logged in.
- Saving user preferences (like dark mode).
- Storing simple app settings.

### If you want temporary storage:
- For temporary, in-memory sharing of data between pages, you would use things like:
  - Passing data via Intents or Bundles.
  - Using a singleton or static variable.
  - ViewModel (in Android Jetpack).

---

**Summary:**  
SharedPreferences are for persistent, simple data storage across app launches, not just for temporary or in-memory sharing. If you want data to be available only while the app is running, use other methods like Intents, Bundles, or in-memory objects.

If you have a specific use case, let me know and I can suggest the best approach!

---

**User**

currently the product contains these all information 

we need to split these exact info into firestore and rtd of firebase , so that we dont need to fetch current price of the product from firestore instead it being stored in the rtd reduces the calls 

---

**Cursor**

Great idea! Splitting your product data between **Firestore** and **Firebase Realtime Database (RTD)** is a common optimization for e-commerce apps, especially for frequently changing fields like price, stock, or discount status.

### Recommended Data Split

#### 1. **Firestore** (for static/rarely changing data)
Store all the product information that doesn't change often:
- `brand`
- `categoryGroup`
- `categoryItem`
- `createdAt`
- `description`
- `imagePath`
- `ingredients`
- `name`
- `nutritionalInfo`
- `productType`
- `sku`
- `weight`

#### 2. **Realtime Database (RTD)** (for dynamic/frequently changing data)
Store only the fields that change often and need to be accessed/updated in real-time:
- `price`
- `quantity`
- `inStock`
- `hasDiscount`
- `updatedAt`

### Example Structure

#### **Firestore (products collection)**
```json
{
  "brand": "Cookie Master",
  "categoryGroup": "bakeries_biscuits",
  "categoryItem": "bakery_snacks",
  "createdAt": "2025-04-20T01:25:53.000Z",
  "description": "Soft and chewy cookies loaded with premium chocolate chips",
  "imagePath": "https://firebasestorage.googleapis.com/...",
  "ingredients": "Refined flour, chocolate chips, butter, sugar, eggs",
  "name": "Chocolate Chip Cookies",
  "nutritionalInfo": "Calories: 200 per serving, Protein: 3g, Carbs: 30g, Fat: 8g",
  "productType": "Bakery Snacks",
  "sku": "BKRY002",
  "weight": "250g"
}
```

#### **Realtime Database (products node)**
```json
{
  "BKRY002": {
    "price": 120,
    "quantity": 15,
    "inStock": true,
    "hasDiscount": true,
    "updatedAt": "2025-04-20T01:25:53.000Z"
  }
}
```
- Here, `"BKRY002"` is the SKU or product ID, used as the key for quick lookup.

---

### **How to Use This Structure**
- **Product listing/details:**  
  Fetch static info from Firestore (one-time or cache it), and fetch price/stock from RTD for real-time updates.
- **Price/stock updates:**  
  Update only the RTD node, which is fast and triggers real-time listeners in your app.

---

### **Benefits**
- **Reduced Firestore reads** for frequently changing fields.
- **Real-time updates** for price/stock in your app UI.
- **Efficient data structure** for both static and dynamic product info.

---

**Let me know if you want code samples for reading/writing this split data, or if you have a specific use case in mind!**

```json
{
  "brand": "Cookie Master",
  "categoryGroup": "bakeries_biscuits",
  "categoryItem": "bakery_snacks",
  "createdAt": "2025-04-20T01:25:53.000Z",
  "description": "Soft and chewy cookies loaded with premium chocolate chips",
  "imagePath": "https://firebasestorage.googleapis.com/...",
  "ingredients": "Refined flour, chocolate chips, butter, sugar, eggs",
  "name": "Chocolate Chip Cookies",
  "nutritionalInfo": "Calories: 200 per serving, Protein: 3g, Carbs: 30g, Fat: 8g",
  "productType": "Bakery Snacks",
  "sku": "BKRY002",
  "weight": "250g"
}
```

```json
{
  "BKRY002": {
    "price": 120,
    "quantity": 15,
    "inStock": true,
    "hasDiscount": true,
    "updatedAt": "2025-04-20T01:25:53.000Z"
  }
}
```

---

**User**

check out the db_upload folder  it contains lots of scripts that help us set  up the database , understand it and tell me how the product collectino was created 

---

**Cursor**

The **product collection** in your Firestore database is created and structured by the script `db_upload/create_products_structure.js`. Here’s how it works:

---

### **How the Product Collection is Created**

1. **Reads Categories:**
   - The script fetches all documents from the `categories` collection.
   - Each document in `categories` represents a product group (e.g., `bakeries_biscuits`, `snacks_drinks`, etc.).

2. **Creates Product Groups:**
   - For each category, it creates an empty document in the `products` collection with the same ID as the category.
   - Example: If a category is `bakeries_biscuits`, it creates `products/bakeries_biscuits`.

3. **Creates Items Subcollections:**
   - For each category, it checks for an `items` subcollection under that category in `categories`.
   - For each item, it creates an empty document in the corresponding path under `products`.
   - Example: If an item is `bakery_snacks` under `bakeries_biscuits`, it creates `products/bakeries_biscuits/items/bakery_snacks`.

4. **Resulting Structure:**
   ```
   products/
     └── categoryGroup (e.g., bakeries_biscuits)
         └── items/
             └── categoryItem (e.g., bakery_snacks)
   ```

5. **Preview Mode:**
   - The script can run in a preview mode (`--preview`), which prints what would be created without actually writing to Firestore.

---

### **What This Script Does NOT Do**
- It does **not** add actual product documents (with fields like name, price, etc.)—it only sets up the structure.
- Actual product data is likely added by scripts like `add_products_bakeries.js`, `add_products_snacks_drinks.js`, etc.

---

**Summary:**  
The `create_products_structure.js` script sets up the Firestore structure for products, mirroring your categories and items, but does not insert product data itself. Product data population is handled by other scripts.

If you want to know how the actual product documents (with all their fields) are added, I can explain the logic from one of the `add_products_*.js` scripts next. Let me know if you want that!

```plaintext
   products/
     └── categoryGroup (e.g., bakeries_biscuits)
         └── items/
             └── categoryItem (e.g., bakery_snacks)
```

---

**User**

keep evereything same just , remove the 

price
quantity
inStock
hasDiscount
updatedAt
these fields for each items and put it to rtd in the same hirerch yas in the firestore 

---

**Cursor**

Here’s how you can **move the dynamic fields** (`price`, `quantity`, `inStock`, `hasDiscount`, `updatedAt`) from Firestore to Firebase Realtime Database (RTD), while keeping the rest of the structure and data in Firestore:

---

## **What to Change**

### 1. **Firestore**
- When uploading product data to Firestore, **remove** the fields:  
  - `price`
  - `quantity`
  - `inStock`
  - `hasDiscount`
  - `updatedAt`
- All other fields remain in Firestore.

### 2. **Realtime Database (RTD)**
- For each product, **add an entry in RTD** with the above fields.
- Use the same hierarchical path as Firestore:  
  `/products/{categoryGroup}/items/{categoryItem}/products/{productId}`

---

## **How to Implement**

### **Step 1: Prepare Firestore Data**
- Before uploading to Firestore, create a copy of the product object **without** the dynamic fields.

### **Step 2: Prepare RTD Data**
- For each product, create a new object **with only** the dynamic fields and upload it to RTD at the matching path.

### **Step 3: Update the Script**
- You’ll need to initialize and use the Firebase RTD SDK in your script.
- After adding a product to Firestore, get its `docRef.id` and use it to set the RTD data.

---

## **Example Code Snippet**

Here’s a conceptual change for your `addProductsToCategory` function:

```js
import { getDatabase, ref, set } from 'firebase/database'; // Add this import

const rtdb = getDatabase(app); // Initialize RTD

async function addProductsToCategory(categoryGroup, categoryItem) {
  const products = productTemplates[categoryItem] || [];
  if (products.length === 0) return;

  for (const product of products) {
    try {
      // Split fields
      const {
        price, quantity, inStock, hasDiscount,

```javascript
import { getDatabase, ref, set } from 'firebase/database'; // Add this import

const rtdb = getDatabase(app); // Initialize RTD

async function addProductsToCategory(categoryGroup, categoryItem) {
  const products = productTemplates[categoryItem] || [];
  if (products.length === 0) return;

  for (const product of products) {
    try {
      // Split fields
      const {
        price, quantity, inStock, hasDiscount,
```

---

**User**

createa a new scvript that reads data from the current database , and then for each product group wise , reuploads eveerything as per what we have decided , with proper loggnng , create this new script 

---

**Cursor**

```javascript
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, setDoc } from 'firebase/firestore';
import { getDatabase, ref, set as rtdSet } from 'firebase/database';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const rtdb = getDatabase(app);

const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

const DYNAMIC_FIELDS = ['price', 'quantity', 'inStock', 'hasDiscount', 'updatedAt'];

async function migrateProducts() {
  console.log('Starting migration of products to Firestore + RTD split...');
  let totalMigrated = 0;
  let totalErrors = 0;

  for (const categoryGroup of CATEGORY_GROUPS) {
    console.log(`\nProcessing category group: ${categoryGroup}`);
    try {
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        console.log(`  Processing item: ${categoryItem}`);
        const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
        for (const productDoc of productsSnapshot.docs) {
          const productId = productDoc.id;
          const productData = productDoc.data();

          // Split static and dynamic fields
          const staticData = { ...productData };
          const dynamicData = {};
          for (const field of DYNAMIC_FIELDS) {
            if (field in staticData) {
              dynamicData[field] = staticData[field];
              delete staticData[field];
            }
          }

          // Overwrite Firestore doc with static data
          try {
            await setDoc(doc(db, 'products', categoryGroup, 'items', categoryItem, 'products', productId), staticData, { merge: false });
            console.log(`    ✓ Firestore static data updated for ${productId}`);
          } catch (err) {
            console.error(`    ✗ Error updating Firestore for ${productId}:`, err);
            totalErrors++;
            continue;
          }

          // Upload dynamic data to RTD
          try {
            const rtdPath = `products/${categoryGroup}/items/${categoryItem}/products/${productId}`;
            await rtdSet(ref(rtdb, rtdPath), dynamicData);
            console.log(`    ✓ RTD dynamic data set for ${productId}`);
          } catch (err) {
            console.error(`    ✗ Error setting RTD for ${productId}:`, err);
            totalErrors++;
            continue;
          }

          totalMigrated++;
        }
      }
    } catch (err) {
      console.error(`  ✗ Error processing group/item:`, err);
      totalErrors++;
    }
  }
  console.log(`\nMigration complete. Total migrated: ${totalMigrated}, Errors: ${totalErrors}`);
}

migrateProducts().then(() => process.exit(0)).catch((err) => {
  console.error('Fatal error during migration:', err);
  process.exit(1);
});

```

A new script named `migrate_products_to_rtd.js` has been created in your `db_upload` folder. Here’s what it does:

---

### **Script Features**

- **Reads all products** from Firestore, group-wise and item-wise.
- **Splits each product** into:
  - **Static fields** (remain in Firestore)
  - **Dynamic fields** (`price`, `quantity`, `inStock`, `hasDiscount`, `updatedAt`) — moved to RTD.
- **Overwrites Firestore** product docs with only static fields.
- **Uploads dynamic fields** to Firebase Realtime Database at the same hierarchical path.
- **Detailed logging** for every step, including errors and success for each product.

---

### **How to Use**

1. **Install dependencies** (if not already):
   ```sh
   npm install
   ```

2. **Run the migration script:**
   ```sh
   node db_upload/migrate_products_to_rtd.js
   ```

---

Would you like to review or customize any part of the script, or proceed with running the migration?

```shellscript
   npm install
```

```shellscript
   node db_upload/migrate_products_to_rtd.js
```

---

**User**

move the discount too in rtdb 

---

**Cursor**

```javascript
// ... existing code ...
const DYNAMIC_FIELDS = ['price', 'quantity', 'inStock', 'hasDiscount', 'updatedAt', 'discount'];
// ... existing code ...
```

The migration script has been updated to also move the `discount` field (if present) from each product to the Realtime Database (RTD), along with the other dynamic fields. It will now be removed from Firestore and stored in RTD at the same hierarchical path.

If you need any further adjustments or want to run the script, let me know!

---

**User**

first go throug hthe script that seeds the discounts , discounts is a collection in firestore that has producid s as doc id and it has info regardingthe discoun of the product 

given this , we jsut need to move the dicounts in rtdb , such that its . disocunts , and then simply the same as its now 

for this fetcvh the disocunts collectino and move it to rtdb , also add logging in this new script 

---

**Cursor**

```javascript
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { getDatabase, ref, set as rtdSet } from 'firebase/database';
import dotenv from 'dotenv';

dotenv.config();

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const rtdb = getDatabase(app);

async function migrateDiscounts() {
  console.log('Starting migration of discounts from Firestore to RTDB...');
  let totalMigrated = 0;
  let totalErrors = 0;

  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    if (discountsSnapshot.empty) {
      console.log('No discounts found in Firestore.');
      return;
    }
    for (const docSnap of discountsSnapshot.docs) {
      const discountId = docSnap.id;
      const discountData = docSnap.data();
      try {
        await rtdSet(ref(rtdb, `discounts/${discountId}`), discountData);
        console.log(`  ✓ Migrated discount for productId: ${discountId}`);
        totalMigrated++;
      } catch (err) {
        console.error(`  ✗ Error migrating discount for productId: ${discountId}:`, err);
        totalErrors++;
      }
    }
  } catch (err) {
    console.error('Fatal error fetching discounts from Firestore:', err);
    totalErrors++;
  }
  console.log(`\nDiscount migration complete. Total migrated: ${totalMigrated}, Errors: ${totalErrors}`);
}

migrateDiscounts().then(() => process.exit(0)).catch((err) => {
  console.error('Fatal error during migration:', err);
  process.exit(1);
});

```

A new script named `migrate_discounts_to_rtdb.js` has been created. Here’s what it does:

---

### **What the Script Does**
- **Reads all documents** from the `discounts` collection in Firestore.
- **Writes each discount** to RTDB under the path:  
  `discounts/{productId}`  
  where `{productId}` is the document ID in Firestore.
- **Logs** each migration step, including successes and errors.
- **Summarizes** the total migrated and any errors at the end.

---

### **How to Use**
1. **Install dependencies** (if not already):
   ```sh
   npm install
   ```

2. **Run the migration script:**
   ```sh
   node db_upload/migrate_discounts_to_rtdb.js
   ```

---

If you want to review, customize, or run the script, let me know!

```shellscript
   npm install
```

```shellscript
   node db_upload/migrate_discounts_to_rtdb.js
```

---

**User**

now researech enrtire codebase to find places which needs to be modified so that they dynamically change when the values change in rtd , it mostly  has to be the product disply in the bestsellers section in home screen and the twopanelvioew and finally the cart page 

also in cart page current its waitin for all the products to be loaded but with this implementation the price canb be calculated much fatser even before the products info get loaded , now its upon user to wait for the products to get loaded or direcy click on place order , 

currently just find and list the files which need chanbes 

---

**Cursor**

Based on your requirements and the codebase search, **the following files and areas will need to be updated** to fetch price, quantity, inStock, hasDiscount, and discount info from RTDB (instead of Firestore) for dynamic product data, and to ensure the UI updates in real-time:

---

### **1. Bestsellers Section (Home Screen)**
- **lib/data/repositories/bestseller_repository_simple.dart**
  - Fetches bestseller product info and discounts; needs to fetch dynamic fields from RTDB.
- **lib/presentation/widgets/grids/simple_bestseller_grid.dart**
  - Displays the bestseller grid; needs to listen for RTDB changes for price/discount.
- **lib/presentation/widgets/cards/bestseller_product_card.dart**
  - Displays individual bestseller product cards; needs to use RTDB data for price/discount.
- **lib/domain/entities/bestseller_product.dart**
  - Combines product and bestseller info; may need to be updated to support RTDB-driven fields.

---

### **2. TwoPanelView (Category/Product Listing)**
- **lib/presentation/widgets/panels/two_panel_category_product_view.dart**
  - Loads and displays products for a category; needs to fetch dynamic fields from RTDB for each product.
- **lib/data/repositories/product/firestore_product_repository.dart**
  - Product fetching logic; needs to merge static Firestore data with dynamic RTDB data.
- **lib/presentation/widgets/cards/universal_product_card.dart** (and similar product card widgets)
  - Product display cards; need to use RTDB data for price/discount.

---

### **3. Cart Page**
- **lib/presentation/pages/cart/cart_page.dart**
  - Cart logic and UI; needs to fetch price/discount from RTDB for each product in the cart.
  - Should allow price calculation before all product details are loaded.
- **lib/data/repositories/cart_repository_impl.dart**
  - Cart repository; needs to fetch product price/discount from RTDB for calculations.
- **lib/data/datasources/firebase/cart/cart_remote_datasource.dart**
  - Remote cart data source; needs to use RTDB for dynamic product fields.
- **lib/services/cart_provider.dart**
  - Cart state management; needs to update when RTDB values change.
- **lib/services/simple_cart_service.dart**
  - Cart operations; needs to use RTDB for price/discount.
- **lib/domain/entities/cart.dart** and **lib/data/models/cart_model.dart**
  - Cart and CartItem entities/models; may need to support dynamic updates from RTDB.

---

### **4. Discount/Price Display Utilities**
- **lib/services/discount/discount_service.dart**
  - Discount calculation and fetching; needs to fetch discount info from RTDB.
- **lib/presentation/widgets/discount/discount_provider.dart**
  - Discount info provider; needs to use RTDB for discount info.
- **lib/presentation/widgets/discount/discount_display_widget.dart**
  - Discount badge widget; needs to listen to RTDB for changes.

---

### **5. Product Card Widgets**
- **lib/presentation/widgets/cards/simple_product_card.dart**
- **lib/presentation/widgets/cards/standard_product_card.dart**
- **lib/presentation/widgets/cards/smart_product_card.dart**
- **lib/presentation/widgets/cards/reusable_product_card.dart**
- **lib/presentation/widgets/cards/enhanced_product_card.dart**
- **lib/presentation/widgets/cards/product_card.dart**
  - All these display product price/discount and need to use RTDB for dynamic fields.

---

### **6. Product Entities/Models**
- **lib/domain/entities/product.dart**
- **lib/data/models/product_model.dart**
  - May need to support merging static Firestore data with dynamic RTDB data.

---

### **Summary Table**

| Area                | Files/Classes/Widgets to Update                                                                 |
|---------------------|-----------------------------------------------------------------------------------------------|
| Bestsellers         | bestseller_repository_simple.dart, simple_bestseller_grid.dart, bestseller_product_card.dart, bestseller_product.dart |
| TwoPanelView        | two_panel_category_product_view.dart, firestore_product_repository.dart, universal_product_card.dart (and similar) |
| Cart Page           | cart_page.dart, cart_repository_impl.dart, cart_remote_datasource.dart, cart_provider.dart, simple_cart_service.dart, cart.dart, cart_model.dart |
| Discount/Price Utils| discount_service.dart, discount_provider.dart, discount_display_widget.dart                   |
| Product Cards       | simple_product_card.dart, standard_product_card.dart, smart_product_card.dart, reusable_product_card.dart, enhanced_product_card.dart, product_card.dart |
| Product Entities    | product.dart, product_model.dart                                                              |

---

**If you want a more detailed breakdown for any specific area, or want to see example code for fetching/merging RTDB data, let me know!**

---

**User**

implement dynamic price display in the cards first , , keep the price being fetched or updated part modular so we need t create it oince and cann be used abnywhere , also the carsds should only be displayed as in stock or not in stock based on the updatd info and the changes should hapen accordingly 

for now just onkly focus on makuing the preice updae itself from the rtd

in  the card being used in twopanelview nd bestsellers , only i these two , and and the card in the cart 

---

**Cursor**

Here’s a plan to implement **dynamic price (and inStock) display** in product cards for the TwoPanelView, Bestsellers, and Cart, using RTDB as the source of truth for dynamic fields:

---

## **Plan**

### 1. **Create a Modular RTDB Product Dynamic Data Provider**
- A Dart class (e.g., `ProductDynamicDataProvider`) that:
  - Listens to RTDB for a given product ID (and its path).
  - Exposes a `Stream<ProductDynamicData>` (containing price, inStock, etc.).
  - Can be reused in any widget.

### 2. **Update Product Cards**
- In the cards used in:
  - **TwoPanelView** (`UniversalProductCard` or similar)
  - **Bestsellers** (`BestsellerProductCard`)
  - **Cart** (`CartProductCard` or similar)
- Wrap the card’s price/inStock display in a `StreamBuilder` that listens to the provider.
- Show loading state until RTDB data is available, then update price/inStock in real time.

### 3. **Keep UI Responsive**
- If RTDB data is not yet loaded, show a shimmer/placeholder or fallback to static Firestore value (optional).
- When RTDB data updates, the card updates instantly.

---

## **Implementation Steps**

### **Step 1: Create ProductDynamicDataProvider**

**lib/services/product/product_dynamic_data_provider.dart**
```dart
import 'package:firebase_database/firebase_database.dart';

class ProductDynamicData {
  final double price;
  final bool inStock;

  ProductDynamicData({required this.price, required this.inStock});
}

class ProductDynamicDataProvider {
  static Stream<ProductDynamicData> getProductStream({
    required String categoryGroup,
    required String categoryItem,
    required String productId,
  }) {
    final ref = FirebaseDatabase.instance.ref(
      'products/$categoryGroup/items/$categoryItem/products/$productId'
    );
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        // Fallback values if not found
        return ProductDynamicData(price: 0, inStock: false);
      }
      return ProductDynamicData(
        price: (data['price'] as num?)?.toDouble() ?? 0,
        inStock: data['inStock'] as bool? ?? false,
      );
    });
  }
}
```

---

### **Step 2: Update Cards to Use the Provider**

#### **A. In TwoPanelView and Bestsellers Cards**
- Wherever you display a product card, wrap the price/inStock display in a `StreamBuilder`:

```dart
StreamBuilder<ProductDynamicData>(
  stream: ProductDynamicDataProvider.getProductStream(
    categoryGroup: product.categoryGroup,
    categoryItem: product.categoryId, // or subcategoryId
    productId: product.id,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      // Show loading or fallback price
      return Text('Loading...');
    }
    final dynamicData = snapshot.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹${dynamicData.price.toStringAsFixed(0)}',
          style: TextStyle(
            color: dynamicData.inStock ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!dynamicData.inStock)
          Text('Out of Stock', style: TextStyle(color: Colors.red)),
      ],
    );
  },
)
```

#### **B. In Cart Product Card**
- Use the same `StreamBuilder` logic for each cart item’s price/inStock.

---

### **Step 3: Modular Usage**
- The `ProductDynamicDataProvider.getProductStream` can be used in any widget/card.
- Only the product’s Firestore path info is needed.

---

## **Files to Update**
- **lib/services/product/product_dynamic_data_provider.dart** (new)
- **lib/presentation/widgets/cards/universal_product_card.dart** (or the card used in TwoPanelView)
- **lib/presentation/widgets/cards/bestseller_product_card.dart**
- **lib/presentation/pages/cart/cart_page.dart** (or the card used in cart)

---

