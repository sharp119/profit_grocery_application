import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs,
  query,
  orderBy
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

/**
 * Get all bestsellers with their productIds and ranks
 */
async function getBestsellers() {
  console.log('Fetching bestsellers...');
  
  try {
    const bestsellersQuery = query(
      collection(db, 'bestsellers'),
      orderBy('rank', 'asc')
    );
    
    const snapshot = await getDocs(bestsellersQuery);
    
    const bestsellers = snapshot.docs.map(doc => ({
      id: doc.id,
      productId: doc.data().productId,
      rank: doc.data().rank
    }));
    
    console.log(`Found ${bestsellers.length} bestsellers`);
    return bestsellers;
  } catch (error) {
    console.error('Error fetching bestsellers:', error);
    return [];
  }
}

/**
 * Get all active discounts with their productIDs
 */
async function getActiveDiscounts() {
  console.log('Fetching active discounts...');
  
  try {
    const now = new Date();
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    
    // Filter active discounts manually
    const activeDiscounts = [];
    
    for (const doc of discountsSnapshot.docs) {
      const discount = doc.data();
      
      if (discount.active !== true) continue;
      
      // Convert timestamps to dates if needed
      const startDate = discount.startTimestamp instanceof Date ? 
        discount.startTimestamp : 
        discount.startTimestamp.toDate();
        
      const endDate = discount.endTimestamp instanceof Date ? 
        discount.endTimestamp : 
        discount.endTimestamp.toDate();
      
      // Check if discount is currently active
      if (startDate <= now && endDate >= now) {
        activeDiscounts.push({
          id: doc.id,
          productId: discount.productID,
          discountType: discount.discountType,
          discountValue: discount.discountValue,
          endDate: endDate
        });
      }
    }
    
    console.log(`Found ${activeDiscounts.length} active discounts`);
    return activeDiscounts;
  } catch (error) {
    console.error('Error fetching active discounts:', error);
    return [];
  }
}

/**
 * Check which bestsellers have discounts
 */
async function checkBestsellerDiscounts() {
  console.log('\n=== BESTSELLER DISCOUNT CHECKER ===\n');
  
  try {
    // 1. Get all bestsellers
    const bestsellers = await getBestsellers();
    
    if (bestsellers.length === 0) {
      console.log('No bestsellers found.');
      return;
    }
    
    // 2. Get all active discounts
    const activeDiscounts = await getActiveDiscounts();
    
    if (activeDiscounts.length === 0) {
      console.log('No active discounts found.');
    }
    
    // 3. Create a map of productId to discount for easy lookup
    const discountMap = {};
    activeDiscounts.forEach(discount => {
      discountMap[discount.productId] = discount;
    });
    
    // 4. Check each bestseller for discount
    console.log('\nRESULTS:');
    console.log('-'.repeat(50));
    
    let discountedBestsellers = 0;
    
    bestsellers.forEach(bestseller => {
      const hasDiscount = discountMap[bestseller.productId] !== undefined;
      
      if (hasDiscount) {
        discountedBestsellers++;
        const discount = discountMap[bestseller.productId];
        const discountDesc = discount.discountType === 'percentage' ? 
          `${discount.discountValue}% off` : 
          `₹${discount.discountValue} off`;
          
        console.log(`#${bestseller.rank}: ProductID: ${bestseller.productId} - HAS DISCOUNT: ${discountDesc} (until ${discount.endDate.toLocaleDateString()})`);
      } else {
        console.log(`#${bestseller.rank}: ProductID: ${bestseller.productId} - No discount`);
      }
    });
    
    // 5. Print summary
    console.log('-'.repeat(50));
    console.log(`\nSUMMARY:`);
    console.log(`Total Bestsellers: ${bestsellers.length}`);
    console.log(`Bestsellers with Discounts: ${discountedBestsellers} (${Math.round(discountedBestsellers/bestsellers.length*100)}%)`);
    console.log(`Bestsellers without Discounts: ${bestsellers.length - discountedBestsellers}`);
    
  } catch (error) {
    console.error('Error checking bestseller discounts:', error);
  }
}

// Run the script
checkBestsellerDiscounts()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Script failed:', error);
    process.exit(1);
  }); 