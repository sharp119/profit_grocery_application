import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  doc, 
  setDoc, 
  where,
  query,
  deleteDoc
} from 'firebase/firestore';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import { createDiscounts } from './create_new_discounts.js';

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

// Number of bestsellers to create
const NUM_BESTSELLERS = 30;
// Number of bestsellers with discounts (6 flat, 6 percentage)
const NUM_FLAT_DISCOUNTED = 6;
const NUM_PERCENTAGE_DISCOUNTED = 6;

/**
 * Get all product IDs from products collection
 */
async function getAllProductIds() {
  console.log('Collecting all product IDs from the database...');
  const allProductIds = [];
  
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
      // Get all items under this category
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        
        // Get all products under this item
        const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
        
        for (const productDoc of productsSnapshot.docs) {
          allProductIds.push(productDoc.id);
        }
      }
    } catch (error) {
      console.error(`Error fetching products from ${categoryGroup}:`, error);
    }
  }
  
  console.log(`Found ${allProductIds.length} products in total.`);
  return allProductIds;
}

/**
 * Get products from discount collection based on discount type
 */
async function getDiscountedProducts(discountType) {
  console.log(`Fetching products with ${discountType} discounts...`);
  
  try {
    // Query discounts collection for active discounts with the specified type
    const discountsSnapshot = await getDocs(
      query(
        collection(db, 'discounts'),
        where('active', '==', true),
        where('discountType', '==', discountType)
      )
    );
    
    // Extract product IDs and discount data
    const discountedProducts = discountsSnapshot.docs.map(doc => ({
      productId: doc.id,
      discountData: doc.data()
    }));
    
    console.log(`Found ${discountedProducts.length} products with ${discountType} discounts.`);
    return discountedProducts;
  } catch (error) {
    console.error(`Error fetching ${discountType} discounted products:`, error);
    return [];
  }
}

/**
 * Clear existing bestsellers collection
 */
async function clearBestsellers() {
  console.log('Clearing existing bestsellers...');
  
  try {
    const bestsellersSnapshot = await getDocs(collection(db, 'bestsellers'));
    
    if (bestsellersSnapshot.empty) {
      console.log('No existing bestsellers found.');
      return;
    }
    
    let count = 0;
    
    for (const docSnapshot of bestsellersSnapshot.docs) {
      await deleteDoc(doc(db, 'bestsellers', docSnapshot.id));
      count++;
    }
    
    console.log(`Deleted ${count} existing bestsellers.`);
  } catch (error) {
    console.error('Error clearing bestsellers:', error);
    throw error;
  }
}

/**
 * Create bestsellers collection 
 */
async function createBestsellers() {
  console.log('\n=== BESTSELLERS GENERATOR ===');
  console.log('='.repeat(40));
  
  try {
    // Step 1: Clear existing bestsellers
    await clearBestsellers();
    
    // Step 2: Get all product IDs
    const allProductIds = await getAllProductIds();
    
    if (allProductIds.length === 0) {
      console.error('No products found in the database. Exiting...');
      return;
    }
    
    // Step 3: Get products with flat discounts
    const flatDiscountProducts = await getDiscountedProducts('flat');
    
    // Step 4: Get products with percentage discounts
    const percentageDiscountProducts = await getDiscountedProducts('percentage');
    
    // Step 5: Select products for bestsellers
    // 6 with flat discounts, 6 with percentage discounts, and the rest random
    
    // Shuffle the arrays
    const shuffledFlat = [...flatDiscountProducts].sort(() => 0.5 - Math.random());
    const shuffledPercentage = [...percentageDiscountProducts].sort(() => 0.5 - Math.random());
    
    // Get the products that are not in the discount collections
    const discountedProductIds = [...shuffledFlat, ...shuffledPercentage].map(p => p.productId);
    const nonDiscountedProductIds = allProductIds.filter(id => !discountedProductIds.includes(id));
    const shuffledNonDiscounted = [...nonDiscountedProductIds].sort(() => 0.5 - Math.random());
    
    // Select products
    const flatBestsellers = shuffledFlat.slice(0, Math.min(NUM_FLAT_DISCOUNTED, shuffledFlat.length));
    const percentageBestsellers = shuffledPercentage.slice(0, Math.min(NUM_PERCENTAGE_DISCOUNTED, shuffledPercentage.length));
    
    const remainingNeeded = NUM_BESTSELLERS - flatBestsellers.length - percentageBestsellers.length;
    const nonDiscountedBestsellers = shuffledNonDiscounted.slice(0, Math.min(remainingNeeded, shuffledNonDiscounted.length));
    
    console.log(`Selected ${flatBestsellers.length} products with flat discounts for bestsellers.`);
    console.log(`Selected ${percentageBestsellers.length} products with percentage discounts for bestsellers.`);
    console.log(`Selected ${nonDiscountedBestsellers.length} non-discounted products for bestsellers.`);
    
    // Step 6: Create bestsellers documents
    let rank = 1;
    
    // Add flat discount bestsellers
    for (const product of flatBestsellers) {
      await setDoc(doc(db, 'bestsellers', product.productId), {
        rank: rank++
      });
      console.log(`Added bestseller rank #${rank-1}: ${product.productId} [FLAT DISCOUNT]`);
    }
    
    // Add percentage discount bestsellers
    for (const product of percentageBestsellers) {
      await setDoc(doc(db, 'bestsellers', product.productId), {
        rank: rank++
      });
      console.log(`Added bestseller rank #${rank-1}: ${product.productId} [PERCENTAGE DISCOUNT]`);
    }
    
    // Add non-discounted bestsellers
    for (const productId of nonDiscountedBestsellers) {
      await setDoc(doc(db, 'bestsellers', productId), {
        rank: rank++
      });
      console.log(`Added bestseller rank #${rank-1}: ${productId}`);
    }
    
    console.log('\n='.repeat(40));
    console.log(`Successfully created ${rank-1} bestsellers.`);
    console.log(`Of these, ${flatBestsellers.length} have flat discounts and ${percentageBestsellers.length} have percentage discounts.`);
    
  } catch (error) {
    console.error('Failed to create bestsellers:', error);
  }
}

// Main function that orchestrates the process
async function main() {
  try {
    // Create the bestsellers
    console.log('Creating bestseller collection...');
    await createBestsellers();
    
    console.log('\nScript completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Script failed:', error);
    process.exit(1);
  }
}

// Run the main function if this is the main module
if (isMainModule) {
  main();
} 