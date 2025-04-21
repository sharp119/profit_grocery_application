import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, setDoc } from 'firebase/firestore';
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

// Function to generate discount data
function generateDiscountData(products) {
  // Current timestamp
  const now = new Date();
  
  // Create an array to hold all discounts
  const discounts = [];
  
  // Constants for discount generation
  const PERCENTAGE_DISCOUNT_MIN = 5;
  const PERCENTAGE_DISCOUNT_MAX = 20;
  const FLAT_DISCOUNT_MIN = 20;
  const FLAT_DISCOUNT_MAX = 100;
  
  // Filter products by price for flat and percentage discounts
  const productsForFlatDiscount = products.filter(p => p.price > 200);
  const productsForPercentageDiscount = [...products]; // All products eligible for percentage
  
  // Shuffle the arrays
  const shuffledFlat = [...productsForFlatDiscount].sort(() => 0.5 - Math.random());
  const shuffledPercentage = [...productsForPercentageDiscount].sort(() => 0.5 - Math.random());
  
  // Calculate how many of each type to create
  // Total: 120 discounts
  const numFlat = Math.min(60, shuffledFlat.length);
  const numPercentage = 120 - numFlat;
  
  console.log(`Creating ${numFlat} flat discounts and ${numPercentage} percentage discounts`);
  
  // Create flat discounts
  for (let i = 0; i < numFlat; i++) {
    if (i >= shuffledFlat.length) break;
    
    const product = shuffledFlat[i];
    
    // Random dates within next month
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + Math.floor(Math.random() * 30) + 1);
    
    // Random flat discount value
    const discountValue = Math.floor(Math.random() * (FLAT_DISCOUNT_MAX - FLAT_DISCOUNT_MIN + 1)) + FLAT_DISCOUNT_MIN;
    
    discounts.push({
      active: true,
      discountType: "flat",
      discountValue: discountValue,
      startTimestamp: startDate,
      endTimestamp: endDate,
      productID: product.id
    });
  }
  
  // Create percentage discounts
  for (let i = 0; i < numPercentage; i++) {
    if (i >= shuffledPercentage.length) break;
    
    const product = shuffledPercentage[i];
    
    // Random dates within next month
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + Math.floor(Math.random() * 30) + 1);
    
    // Random percentage discount value
    const discountValue = Math.floor(Math.random() * (PERCENTAGE_DISCOUNT_MAX - PERCENTAGE_DISCOUNT_MIN + 1)) + PERCENTAGE_DISCOUNT_MIN;
    
    discounts.push({
      active: true,
      discountType: "percentage",
      discountValue: discountValue,
      startTimestamp: startDate,
      endTimestamp: endDate,
      productID: product.id
    });
  }
  
  return discounts;
}

// Function to add discounts to Firestore
async function addDiscountsToFirestore(discounts) {
  console.log(`Adding ${discounts.length} discounts to Firestore...`);
  
  try {
    // First, clear existing discounts
    const existingDiscounts = await getDocs(collection(db, 'discounts'));
    console.log(`Found ${existingDiscounts.docs.length} existing discounts to delete`);
    
    for (const docSnapshot of existingDiscounts.docs) {
      await setDoc(doc(db, 'discounts', docSnapshot.id), { deleted: true }, { merge: true });
      console.log(`Marked discount ${docSnapshot.id} as deleted`);
    }
    
    // Add each discount with ID same as productID
    for (const discount of discounts) {
      // Use productID as the document ID
      await setDoc(doc(db, 'discounts', discount.productID), discount);
      console.log(`Added discount for product ${discount.productID} (${discount.discountType}: ${discount.discountValue})`);
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
    return discounts; // Return discounts for potential use in bestseller script
  } catch (error) {
    console.error('Error in discount creation process:', error);
  }
}

// Export for use in bestseller script
export { createDiscounts };

// Execute the script if run directly (ES module version)
if (isMainModule) {
  createDiscounts()
    .then(() => {
      console.log('Script execution completed.');
      process.exit(0);
    })
    .catch(error => {
      console.error('Script failed:', error);
      process.exit(1);
    });
} 