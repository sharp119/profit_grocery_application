import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, setDoc, deleteDoc } from 'firebase/firestore';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

// ES modules equivalent for the require.main === module pattern
const __filename = fileURLToPath(import.meta.url);
const isMainModule = process.argv[1] === __filename;

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

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Get all product IDs with their full path and price information
 */
async function getAllProductsWithPaths() {
  console.log('Fetching all products with their full paths...');
  
  const allProducts = [];
  
  // List of all category groups
  const CATEGORY_GROUPS = [
    'bakeries_biscuits',
    'beauty_hygiene',
    'dairy_eggs',
    'fruits_vegetables',
    'grocery_kitchen',
    'snacks_drinks'
  ];
  
  for (const categoryGroup of CATEGORY_GROUPS) {
    try {
      console.log(`Fetching products from category group: ${categoryGroup}`);
      
      // Get all items under this category
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        
        // Get all products under this item
        const productsPath = `products/${categoryGroup}/items/${categoryItem}/products`;
        console.log(`Fetching products from: ${productsPath}`);
        
        const productsSnapshot = await getDocs(collection(db, productsPath));
        
        for (const productDoc of productsSnapshot.docs) {
          const productData = productDoc.data();
          const productFullPath = `${productsPath}/${productDoc.id}`;
          
          allProducts.push({
            id: productDoc.id,
            path: productFullPath,
            price: productData.price || 0,
            name: productData.name || 'Unknown Product'
          });
          
          console.log(`Found product: ID=${productDoc.id}, Name=${productData.name}, Price=${productData.price}, Path=${productFullPath}`);
        }
      }
    } catch (error) {
      console.error(`Error fetching products from ${categoryGroup}:`, error);
    }
  }
  
  console.log(`Found ${allProducts.length} products in total.`);
  return allProducts;
}

/**
 * Clear existing discounts in the discounts collection
 */
async function clearExistingDiscounts() {
  console.log('\nClearing existing discounts...');
  
  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    
    if (discountsSnapshot.empty) {
      console.log('No existing discounts found.');
      return;
    }
    
    let count = 0;
    
    for (const docSnapshot of discountsSnapshot.docs) {
      await deleteDoc(doc(db, 'discounts', docSnapshot.id));
      count++;
      console.log(`Deleted discount: ${docSnapshot.id}`);
    }
    
    console.log(`Deleted ${count} existing discounts.`);
  } catch (error) {
    console.error('Error clearing discounts:', error);
  }
}

/**
 * Generate and add discounts for selected products
 */
async function createDiscounts(allProducts) {
  console.log('\nCreating discounts for selected products...');
  
  // Constants for discount generation
  const PERCENTAGE_DISCOUNT_MIN = 5;
  const PERCENTAGE_DISCOUNT_MAX = 20;
  const FLAT_DISCOUNT_MIN = 20;
  const FLAT_DISCOUNT_MAX = 100;
  
  // Shuffle products for random selection
  const shuffledProducts = [...allProducts].sort(() => 0.5 - Math.random());
  
  // Select 120 products (or as many as available if less than 120)
  const selectedProducts = shuffledProducts.slice(0, Math.min(120, shuffledProducts.length));
  console.log(`Selected ${selectedProducts.length} products for discounts.`);
  
  // Track discount types for reporting
  const discountStats = {
    flat: 0,
    percentage: 0
  };
  
  // Create discounts for each selected product
  for (const product of selectedProducts) {
    // Determine discount type based on price
    let discountType;
    
    if (product.price > 200) {
      // For products > 200 Rs, randomly choose flat or percentage
      discountType = Math.random() < 0.5 ? 'flat' : 'percentage';
      console.log(`Product ${product.id} price (${product.price}) > 200, randomly selected ${discountType} discount`);
    } else {
      // For products <= 200 Rs, always use percentage
      discountType = 'percentage';
      console.log(`Product ${product.id} price (${product.price}) <= 200, using percentage discount`);
    }
    
    // Generate discount value based on type
    let discountValue;
    if (discountType === 'flat') {
      discountValue = Math.floor(Math.random() * (FLAT_DISCOUNT_MAX - FLAT_DISCOUNT_MIN + 1)) + FLAT_DISCOUNT_MIN;
      discountStats.flat++;
    } else {
      discountValue = Math.floor(Math.random() * (PERCENTAGE_DISCOUNT_MAX - PERCENTAGE_DISCOUNT_MIN + 1)) + PERCENTAGE_DISCOUNT_MIN;
      discountStats.percentage++;
    }
    
    // Create date range (current date to 30 days in future)
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + Math.floor(Math.random() * 30) + 1);
    
    // Create the discount object
    const discount = {
      active: true,
      discountType: discountType,
      discountValue: discountValue,
      startTimestamp: startDate,
      endTimestamp: endDate,
      productID: product.id
    };
    
    // Add to Firestore using product ID as document ID
    try {
      await setDoc(doc(db, 'discounts', product.id), discount);
      console.log(`Created ${discountType} discount of ${discountValue} for product ${product.id} (${product.name})`);
    } catch (error) {
      console.error(`Error creating discount for product ${product.id}:`, error);
    }
  }
  
  // Report discount distribution
  console.log('\nDiscount Creation Summary:');
  console.log(`Total discounts created: ${discountStats.flat + discountStats.percentage}`);
  console.log(`Flat discounts: ${discountStats.flat}`);
  console.log(`Percentage discounts: ${discountStats.percentage}`);
  
  return {
    totalCreated: discountStats.flat + discountStats.percentage,
    flatCount: discountStats.flat,
    percentageCount: discountStats.percentage
  };
}

/**
 * Main function to execute the script
 */
async function createVerifiedDiscounts() {
  try {
    console.log('Starting verified discount creation process...');
    
    // Step 1: Get all products with paths
    const allProducts = await getAllProductsWithPaths();
    
    if (allProducts.length === 0) {
      console.error('No products found in the database. Cannot create discounts.');
      return;
    }
    
    // Step 2: Clear existing discounts
    await clearExistingDiscounts();
    
    // Step 3: Create new discounts
    const discountStats = await createDiscounts(allProducts);
    
    console.log('\nVerified discount creation completed successfully!');
    console.log(`Created ${discountStats.totalCreated} discounts in total:`);
    console.log(`- ${discountStats.flatCount} flat discounts`);
    console.log(`- ${discountStats.percentageCount} percentage discounts`);
    
  } catch (error) {
    console.error('Error in verified discount creation process:', error);
  }
}

// Execute the script if run directly
if (isMainModule) {
  createVerifiedDiscounts()
    .then(() => {
      console.log('\nScript execution completed.');
      process.exit(0);
    })
    .catch(error => {
      console.error('Script failed:', error);
      process.exit(1);
    });
} 