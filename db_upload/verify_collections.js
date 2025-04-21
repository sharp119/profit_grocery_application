import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  query,
  where
} from 'firebase/firestore';
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
 * Get all product IDs from the products collection
 */
async function getAllProductIds() {
  console.log('Fetching all product IDs...');
  const allProductIds = new Set();
  
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
          allProductIds.add(productDoc.id);
        }
      }
    } catch (error) {
      console.error(`Error fetching products from ${categoryGroup}:`, error);
    }
  }
  
  console.log(`Found ${allProductIds.size} products in total.`);
  return allProductIds;
}

/**
 * Get all discounts from the discounts collection
 */
async function getAllDiscounts() {
  console.log('Fetching all discounts...');
  
  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    
    const discounts = {
      flat: [],
      percentage: [],
      invalid: [],
      total: discountsSnapshot.docs.length
    };
    
    for (const doc of discountsSnapshot.docs) {
      const data = doc.data();
      if (data.discountType === 'flat') {
        discounts.flat.push({
          id: doc.id,
          ...data
        });
      } else if (data.discountType === 'percentage') {
        discounts.percentage.push({
          id: doc.id,
          ...data
        });
      } else {
        discounts.invalid.push({
          id: doc.id,
          ...data
        });
      }
    }
    
    console.log(`Found ${discounts.total} discounts (${discounts.flat.length} flat, ${discounts.percentage.length} percentage, ${discounts.invalid.length} invalid).`);
    return discounts;
  } catch (error) {
    console.error('Error fetching discounts:', error);
    return { flat: [], percentage: [], invalid: [], total: 0 };
  }
}

/**
 * Get all bestsellers from the bestsellers collection
 */
async function getAllBestsellers() {
  console.log('Fetching all bestsellers...');
  
  try {
    const bestsellersSnapshot = await getDocs(collection(db, 'bestsellers'));
    
    const bestsellers = bestsellersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    console.log(`Found ${bestsellers.length} bestsellers.`);
    return bestsellers;
  } catch (error) {
    console.error('Error fetching bestsellers:', error);
    return [];
  }
}

/**
 * Verify that all discounts reference valid products
 */
function verifyDiscounts(discounts, allProductIds) {
  console.log('\n=== VERIFYING DISCOUNTS ===');
  
  const invalidDiscounts = [];
  
  // Check flat discounts
  console.log(`Verifying ${discounts.flat.length} flat discounts...`);
  for (const discount of discounts.flat) {
    if (!allProductIds.has(discount.id)) {
      invalidDiscounts.push({
        id: discount.id,
        type: 'flat',
        reason: 'Product ID does not exist in products collection'
      });
    }
  }
  
  // Check percentage discounts
  console.log(`Verifying ${discounts.percentage.length} percentage discounts...`);
  for (const discount of discounts.percentage) {
    if (!allProductIds.has(discount.id)) {
      invalidDiscounts.push({
        id: discount.id,
        type: 'percentage',
        reason: 'Product ID does not exist in products collection'
      });
    }
  }
  
  // Report results
  if (invalidDiscounts.length === 0) {
    console.log('✅ All discounts reference valid products.');
  } else {
    console.log(`❌ Found ${invalidDiscounts.length} invalid discounts:`);
    for (const invalid of invalidDiscounts) {
      console.log(`  - ID: ${invalid.id}, Type: ${invalid.type}, Reason: ${invalid.reason}`);
    }
  }
  
  return {
    valid: invalidDiscounts.length === 0,
    invalidCount: invalidDiscounts.length,
    invalidDiscounts
  };
}

/**
 * Verify that all bestsellers reference valid products
 */
function verifyBestsellers(bestsellers, allProductIds, discounts) {
  console.log('\n=== VERIFYING BESTSELLERS ===');
  
  const invalidBestsellers = [];
  const discountedBestsellers = {
    flat: [],
    percentage: []
  };
  
  // Create a map of discounted product IDs for faster lookup
  const flatDiscountIds = new Set(discounts.flat.map(d => d.id));
  const percentageDiscountIds = new Set(discounts.percentage.map(d => d.id));
  
  // Verify each bestseller
  for (const bestseller of bestsellers) {
    // Check if product exists
    if (!allProductIds.has(bestseller.id)) {
      invalidBestsellers.push({
        id: bestseller.id,
        reason: 'Product ID does not exist in products collection'
      });
      continue;
    }
    
    // Track discounted bestsellers
    if (flatDiscountIds.has(bestseller.id)) {
      discountedBestsellers.flat.push(bestseller);
    } else if (percentageDiscountIds.has(bestseller.id)) {
      discountedBestsellers.percentage.push(bestseller);
    }
  }
  
  // Report results
  if (invalidBestsellers.length === 0) {
    console.log('✅ All bestsellers reference valid products.');
  } else {
    console.log(`❌ Found ${invalidBestsellers.length} invalid bestsellers:`);
    for (const invalid of invalidBestsellers) {
      console.log(`  - ID: ${invalid.id}, Reason: ${invalid.reason}`);
    }
  }
  
  // Check discounted bestsellers distribution
  console.log(`\nBestseller Distribution:`);
  console.log(`  - Total bestsellers: ${bestsellers.length}`);
  console.log(`  - With flat discounts: ${discountedBestsellers.flat.length} (target: 6)`);
  console.log(`  - With percentage discounts: ${discountedBestsellers.percentage.length} (target: 6)`);
  console.log(`  - Without discounts: ${bestsellers.length - discountedBestsellers.flat.length - discountedBestsellers.percentage.length}`);
  
  // Validate against targets
  if (discountedBestsellers.flat.length === 6 && discountedBestsellers.percentage.length === 6) {
    console.log('✅ Bestsellers have the correct distribution of discounted products.');
  } else {
    console.log('❌ Bestsellers do not have the correct distribution of discounted products.');
    if (discountedBestsellers.flat.length !== 6) {
      console.log(`  - Expected 6 bestsellers with flat discounts, found ${discountedBestsellers.flat.length}`);
    }
    if (discountedBestsellers.percentage.length !== 6) {
      console.log(`  - Expected 6 bestsellers with percentage discounts, found ${discountedBestsellers.percentage.length}`);
    }
  }
  
  return {
    valid: invalidBestsellers.length === 0,
    correctDistribution: discountedBestsellers.flat.length === 6 && discountedBestsellers.percentage.length === 6,
    invalidCount: invalidBestsellers.length,
    discountedCounts: {
      flat: discountedBestsellers.flat.length,
      percentage: discountedBestsellers.percentage.length
    },
    invalidBestsellers
  };
}

/**
 * Main verification function
 */
async function verifyCollections() {
  console.log('Starting verification process...');
  
  try {
    // Step 1: Get all product IDs
    const allProductIds = await getAllProductIds();
    
    // Step 2: Get all discounts
    const discounts = await getAllDiscounts();
    
    // Step 3: Get all bestsellers
    const bestsellers = await getAllBestsellers();
    
    // Step 4: Verify discounts
    const discountVerification = verifyDiscounts(discounts, allProductIds);
    
    // Step 5: Verify bestsellers
    const bestsellerVerification = verifyBestsellers(bestsellers, allProductIds, discounts);
    
    // Step 6: Report overall results
    console.log('\n=== VERIFICATION SUMMARY ===');
    if (discountVerification.valid && bestsellerVerification.valid && bestsellerVerification.correctDistribution) {
      console.log('✅ All checks passed. Discounts and bestsellers are valid.');
    } else {
      console.log('❌ Some checks failed.');
      if (!discountVerification.valid) {
        console.log(`  - ${discountVerification.invalidCount} discounts reference invalid products.`);
      }
      if (!bestsellerVerification.valid) {
        console.log(`  - ${bestsellerVerification.invalidCount} bestsellers reference invalid products.`);
      }
      if (!bestsellerVerification.correctDistribution) {
        console.log('  - Bestsellers do not have the correct distribution of discounted products.');
      }
    }
    
  } catch (error) {
    console.error('Error during verification:', error);
  }
}

// Execute the script if run directly
if (isMainModule) {
  verifyCollections()
    .then(() => {
      console.log('\nVerification complete.');
      process.exit(0);
    })
    .catch(error => {
      console.error('Verification failed:', error);
      process.exit(1);
    });
} 