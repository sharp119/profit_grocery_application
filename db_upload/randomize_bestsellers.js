import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  deleteDoc, 
  addDoc, 
  query,
  orderBy,
  writeBatch,
  doc
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
 * Get all product IDs from all categories
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
          allProductIds.push({
            id: productDoc.id,
            name: productDoc.data().name || 'Unknown Product',
            categoryGroup,
            categoryItem
          });
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
 * Create new bestsellers with random products
 */
async function createRandomBestsellers(productIds) {
  console.log(`\nCreating ${NUM_BESTSELLERS} random bestsellers...`);
  
  try {
    // Shuffle and pick the first NUM_BESTSELLERS
    const shuffledProducts = shuffleArray([...productIds]);
    const selectedProducts = shuffledProducts.slice(0, NUM_BESTSELLERS);
    
    if (selectedProducts.length < NUM_BESTSELLERS) {
      console.warn(`Warning: Only ${selectedProducts.length} products available for bestsellers.`);
    }
    
    // Create new bestsellers with ranks 1 to NUM_BESTSELLERS
    const bestsellersRef = collection(db, 'bestsellers');
    let rank = 1;
    
    for (const product of selectedProducts) {
      await addDoc(bestsellersRef, {
        productId: product.id,
        rank: rank++
      });
      
      console.log(`✓ Added bestseller rank #${rank-1}: ${product.name} (${product.id})`);
      console.log(`  From: ${product.categoryGroup} > ${product.categoryItem}`);
    }
    
    console.log(`\nSuccessfully created ${selectedProducts.length} bestsellers.`);
  } catch (error) {
    console.error('Error creating bestsellers:', error);
    throw error;
  }
}

/**
 * Main function to update bestsellers
 */
async function updateRandomBestsellers() {
  console.log('\n=== RANDOM BESTSELLERS GENERATOR ===');
  console.log('='.repeat(40));
  
  try {
    // Step 1: Get all product IDs
    const allProductIds = await getAllProductIds();
    
    if (allProductIds.length === 0) {
      console.error('No products found in the database. Exiting...');
      return;
    }
    
    // Step 2: Clear existing bestsellers
    await clearBestsellers();
    
    // Step 3: Create new random bestsellers
    await createRandomBestsellers(allProductIds);
    
    console.log('\n='.repeat(40));
    console.log('Bestsellers have been successfully randomized!');
    console.log(`${NUM_BESTSELLERS} products are now featured as bestsellers.`);
    
  } catch (error) {
    console.error('Failed to update bestsellers:', error);
  }
}

// Run the function
updateRandomBestsellers()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
