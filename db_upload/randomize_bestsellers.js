import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  addDoc, 
  writeBatch,
  doc,
  where,
  query
} from 'firebase/firestore';
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

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// List of all category groups
const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

// Number of bestsellers to create
const NUM_BESTSELLERS = 20;
// Number of bestsellers that should have discounts
const NUM_DISCOUNTED_BESTSELLERS = 12;

/**
 * Shuffle array using Fisher-Yates algorithm
 */
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

/**
 * Get all product IDs
 */
async function getAllProductIds() {
  console.log('Collecting all product IDs from the database...');
  const allProductIds = [];
  
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
 * Get product IDs that have active discounts
 */
async function getDiscountedProductIds() {
  console.log('Fetching products with active discounts...');
  
  try {
    const currentDate = new Date();
    
    // Query for active discounts where current date is between start and end timestamp
    const discountsSnapshot = await getDocs(
      query(
        collection(db, 'discounts'),
        where('active', '==', true),
        where('startTimestamp', '<=', currentDate),
        where('endTimestamp', '>=', currentDate)
      )
    );
    
    // Extract productIDs from discounts
    const discountedProductIds = discountsSnapshot.docs.map(doc => doc.data().productID);
    
    console.log(`Found ${discountedProductIds.length} products with active discounts.`);
    return discountedProductIds;
  } catch (error) {
    console.error('Error fetching discounted products:', error);
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
    
    const batch = writeBatch(db);
    let count = 0;
    
    for (const docSnapshot of bestsellersSnapshot.docs) {
      batch.delete(doc(db, 'bestsellers', docSnapshot.id));
      count++;
    }
    
    await batch.commit();
    console.log(`Deleted ${count} existing bestsellers.`);
  } catch (error) {
    console.error('Error clearing bestsellers:', error);
    throw error;
  }
}

/**
 * Create bestsellers collection with 12 discounted products and 8 regular products
 */
async function createSimpleBestsellers(allProductIds, discountedProductIds) {
  console.log('\nCreating bestsellers collection...');
  
  try {
    // Get non-discounted product IDs
    const nonDiscountedProductIds = allProductIds.filter(id => !discountedProductIds.includes(id));
    
    console.log(`Found ${discountedProductIds.length} discounted products.`);
    console.log(`Found ${nonDiscountedProductIds.length} non-discounted products.`);
    
    // Shuffle both arrays
    const shuffledDiscountedIds = shuffleArray([...discountedProductIds]);
    const shuffledNonDiscountedIds = shuffleArray([...nonDiscountedProductIds]);
    
    // Select products for bestsellers
    const discountedBestsellers = shuffledDiscountedIds.slice(
      0, 
      Math.min(NUM_DISCOUNTED_BESTSELLERS, shuffledDiscountedIds.length)
    );
    
    const numRegularNeeded = NUM_BESTSELLERS - discountedBestsellers.length;
    const nonDiscountedBestsellers = shuffledNonDiscountedIds.slice(
      0, 
      Math.min(numRegularNeeded, shuffledNonDiscountedIds.length)
    );
    
    // Create array of all bestseller product IDs
    const bestsellers = [...discountedBestsellers, ...nonDiscountedBestsellers];
    
    if (bestsellers.length < NUM_BESTSELLERS) {
      console.warn(`Warning: Only able to create ${bestsellers.length} bestsellers due to available products.`);
    }
    
    // Add bestsellers to Firestore
    const bestsellersRef = collection(db, 'bestsellers');
    let rank = 1;
    
    for (const productId of bestsellers) {
      await addDoc(bestsellersRef, {
        productId: productId,
        rank: rank++
      });
      
      const isDiscounted = discountedProductIds.includes(productId);
      console.log(`✓ Added bestseller rank #${rank-1}: ${productId} ${isDiscounted ? '[DISCOUNTED]' : ''}`);
    }
    
    console.log(`\nSuccessfully created ${bestsellers.length} bestsellers.`);
    console.log(`Of these, ${discountedBestsellers.length} have active discounts.`);
  } catch (error) {
    console.error('Error creating bestsellers:', error);
    throw error;
  }
}

/**
 * Main function to create bestsellers
 */
async function createBestsellers() {
  console.log('\n=== SIMPLE BESTSELLERS GENERATOR ===');
  console.log('='.repeat(40));
  
  try {
    // Step 1: Get all product IDs
    const allProductIds = await getAllProductIds();
    
    if (allProductIds.length === 0) {
      console.error('No products found in the database. Exiting...');
      return;
    }
    
    // Step 2: Get all products with discounts
    const discountedProductIds = await getDiscountedProductIds();
    
    if (discountedProductIds.length === 0) {
      console.warn('Warning: No discounted products found. Creating bestsellers with only regular products.');
    }
    
    // Step 3: Clear existing bestsellers
    await clearBestsellers();
    
    // Step 4: Create new bestsellers
    await createSimpleBestsellers(allProductIds, discountedProductIds);
    
    console.log('\n='.repeat(40));
    console.log('Bestsellers have been successfully created!');
    
  } catch (error) {
    console.error('Failed to create bestsellers:', error);
  }
}

// Run the function
createBestsellers()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
