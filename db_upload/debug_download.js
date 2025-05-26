import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
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

async function debugDownload() {
  try {
    console.log('🔍 DEBUG: Starting download process...');
    
    // Step 1: Check products collection
    console.log('📂 Step 1: Checking products collection...');
    const productsRef = collection(db, 'products');
    const productsSnapshot = await getDocs(productsRef);
    
    if (productsSnapshot.empty) {
      console.log('❌ Products collection is empty or doesn\'t exist');
      console.log('💡 Trying to check what collections DO exist...');
      
      // Check some common collections
      const collectionsToCheck = ['categories', 'users', 'orders', 'discounts', 'bestsellers'];
      
      for (const collectionName of collectionsToCheck) {
        try {
          const testRef = collection(db, collectionName);
          const testSnapshot = await getDocs(testRef);
          console.log(`   ${collectionName}: ${testSnapshot.empty ? 'Empty' : `${testSnapshot.docs.length} documents`}`);
        } catch (error) {
          console.log(`   ${collectionName}: Error (${error.message})`);
        }
      }
      
      return;
    }
    
    console.log(`✅ Found ${productsSnapshot.docs.length} category groups in products collection`);
    
    // Step 2: List all category groups
    console.log('📋 Step 2: Category groups found:');
    for (const categoryGroupDoc of productsSnapshot.docs) {
      const categoryGroup = categoryGroupDoc.id;
      console.log(`   - ${categoryGroup}`);
      
      // Step 3: Check items in each category group
      try {
        const itemsRef = collection(db, 'products', categoryGroup, 'items');
        const itemsSnapshot = await getDocs(itemsRef);
        
        if (itemsSnapshot.empty) {
          console.log(`     ⚠️  No items in ${categoryGroup}`);
        } else {
          console.log(`     ✅ ${itemsSnapshot.docs.length} items in ${categoryGroup}:`);
          
          // Step 4: Check first few items for products
          let itemCount = 0;
          for (const itemDoc of itemsSnapshot.docs) {
            const categoryItem = itemDoc.id;
            console.log(`       - ${categoryItem}`);
            
            // Check if this item has products
            try {
              const productsRef = collection(db, 'products', categoryGroup, 'items', categoryItem, 'products');
              const productSnapshot = await getDocs(productsRef);
              console.log(`         Products: ${productSnapshot.docs.length}`);
              
              if (productSnapshot.docs.length > 0) {
                // Show first product as example
                const firstProduct = productSnapshot.docs[0].data();
                console.log(`         Example: ${firstProduct.name || 'No name'} - $${firstProduct.price || 'No price'}`);
              }
            } catch (error) {
              console.log(`         Products: Error (${error.message})`);
            }
            
            // Only check first 3 items to avoid spam
            itemCount++;
            if (itemCount >= 3) {
              if (itemsSnapshot.docs.length > 3) {
                console.log(`       ... and ${itemsSnapshot.docs.length - 3} more items`);
              }
              break;
            }
          }
        }
      } catch (error) {
        console.log(`     ❌ Error checking items in ${categoryGroup}: ${error.message}`);
      }
    }
    
    console.log('🎉 Debug completed successfully!');
    
  } catch (error) {
    console.error('💥 Debug failed:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      stack: error.stack?.split('\\n')[0] // Just first line of stack
    });
  }
}

debugDownload().then(() => {
  console.log('✅ Debug script finished');
  process.exit(0);
}).catch(error => {
  console.error('💥 Debug script crashed:', error.message);
  process.exit(1);
});
