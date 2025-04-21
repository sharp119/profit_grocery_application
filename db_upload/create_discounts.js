import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs, doc, setDoc } from 'firebase/firestore';
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

// Function to fetch all product IDs and prices
async function getAllProducts() {
  try {
    console.log('Fetching all products...');
    
    const allProducts = [];
    
    // Get all category groups
    const categoryGroupsSnapshot = await getDocs(collection(db, 'products'));
    
    for (const groupDoc of categoryGroupsSnapshot.docs) {
      const categoryGroup = groupDoc.id;
      
      // Get category items for this group
      const categoryItemsSnapshot = await getDocs(collection(db, `products/${categoryGroup}/items`));
      
      for (const itemDoc of categoryItemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        
        // Get products in this category item
        const productsSnapshot = await getDocs(
          collection(db, `products/${categoryGroup}/items/${categoryItem}/products`)
        );
        
        for (const productDoc of productsSnapshot.docs) {
          const productData = productDoc.data();
          allProducts.push({
            id: productDoc.id,
            price: productData.price
          });
        }
      }
    }
    
    console.log(`Found ${allProducts.length} products`);
    return allProducts;
  } catch (error) {
    console.error('Error fetching products:', error);
    throw error;
  }
}

// Function to generate random discount data
function generateDiscountData(products) {
  // Current timestamp
  const now = new Date();
  
  // Create an array to hold all discounts
  const discounts = [];
  
  // Constants for discount generation
  const MIN_DISCOUNT_DAYS = 3;
  const MAX_DISCOUNT_DAYS = 14;
  const PERCENTAGE_DISCOUNT_MIN = 5;
  const PERCENTAGE_DISCOUNT_MAX = 40;
  const VALUE_DISCOUNT_MIN = 20;
  const VALUE_DISCOUNT_MAX = 100;
  
  // Select 180 random products for discounts
  // If there aren't enough products, we'll use what we have and recycle
  const productsToUse = [];
  while (productsToUse.length < 180) {
    const availableProducts = [...products];
    const shuffled = availableProducts.sort(() => 0.5 - Math.random());
    productsToUse.push(...shuffled.slice(0, Math.min(180 - productsToUse.length, shuffled.length)));
  }
  
  // Create 180 discounts
  for (let i = 0; i < 180; i++) {
    const product = productsToUse[i];
    
    // Random discount duration between MIN and MAX days
    const durationDays = MIN_DISCOUNT_DAYS + Math.floor(Math.random() * (MAX_DISCOUNT_DAYS - MIN_DISCOUNT_DAYS + 1));
    
    // Start date: random from now to 7 days in the future
    const startOffset = Math.floor(Math.random() * 7 * 24 * 60 * 60 * 1000);
    const startDate = new Date(now.getTime() + startOffset);
    
    // End date: start date + duration
    const endDate = new Date(startDate.getTime() + (durationDays * 24 * 60 * 60 * 1000));
    
    // Determine discount type and value
    const isPercentage = product.price <= 200 || Math.random() < 0.5;
    
    let discountValue;
    
    if (isPercentage) {
      // Percentage discount (5-40%)
      discountValue = PERCENTAGE_DISCOUNT_MIN + 
        Math.floor(Math.random() * (PERCENTAGE_DISCOUNT_MAX - PERCENTAGE_DISCOUNT_MIN + 1));
    } else {
      // Flat value discount (20-100 Rs) for products > 200 Rs
      discountValue = VALUE_DISCOUNT_MIN + 
        Math.floor(Math.random() * (VALUE_DISCOUNT_MAX - VALUE_DISCOUNT_MIN + 1));
    }
    
    // Create the simplified discount object
    const discount = {
      productID: product.id,
      startTimestamp: startDate,
      endTimestamp: endDate,
      discountType: isPercentage ? 'percentage' : 'flat',
      discountValue: discountValue,
      active: true
    };
    
    discounts.push(discount);
  }
  
  return discounts;
}

// Function to add discounts to Firestore
async function addDiscountsToFirestore(discounts) {
  console.log(`Adding ${discounts.length} discounts to Firestore...`);
  
  try {
    // Create a discounts collection if it doesn't exist already
    const discountsRef = collection(db, 'discounts');
    
    // Add each discount as a document with auto-generated ID
    for (const discount of discounts) {
      await addDoc(discountsRef, discount);
    }
    
    console.log('All discounts added successfully!');
  } catch (error) {
    console.error('Error adding discounts:', error);
    throw error;
  }
}

// Main function to execute the script
async function createDiscounts() {
  try {
    console.log('Starting discount creation process...');
    
    // 1. Get all products
    const products = await getAllProducts();
    
    if (products.length === 0) {
      console.error('No products found in the database. Cannot create discounts.');
      return;
    }
    
    // 2. Generate discount data
    const discounts = generateDiscountData(products);
    
    // 3. Add discounts to Firestore
    await addDiscountsToFirestore(discounts);
    
    console.log('Discount creation completed successfully!');
  } catch (error) {
    console.error('Error in discount creation process:', error);
  }
}

// Execute the script
createDiscounts(); 