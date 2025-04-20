import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  doc, 
  setDoc, 
  deleteDoc, 
  addDoc, 
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

async function updateBestsellersStructure() {
  console.log('\nUpdating bestsellers collection structure...');
  console.log('='.repeat(50));
  
  try {
    // Get all existing bestsellers
    const bestsellersRef = collection(db, 'bestsellers');
    const bestsellersSnapshot = await getDocs(query(bestsellersRef, orderBy('rank')));
    
    console.log(`Found ${bestsellersSnapshot.size} bestseller documents.`);
    
    // Skip if no bestsellers exist
    if (bestsellersSnapshot.empty) {
      console.log('No bestsellers found. Nothing to update.');
      return;
    }
    
    console.log('\nCreating new simplified bestseller entries...');
    let success = 0;
    let error = 0;
    
    // Create a batch for the operations
    for (const bestsellerDoc of bestsellersSnapshot.docs) {
      try {
        const data = bestsellerDoc.data();
        const oldId = bestsellerDoc.id;
        
        // Extract only the required fields
        const simplifiedData = {
          productId: data.productId,
          rank: data.rank || 999 // Default high rank if missing
        };
        
        // Add a new document with auto-generated ID
        await addDoc(bestsellersRef, simplifiedData);
        
        // Delete the old document
        await deleteDoc(doc(db, 'bestsellers', oldId));
        
        console.log(`✓ Processed bestseller: ${oldId} -> Auto-generated ID`);
        console.log(`  Product ID: ${simplifiedData.productId}`);
        console.log(`  Rank: ${simplifiedData.rank}`);
        success++;
      } catch (err) {
        console.error(`✗ Error processing bestseller ${bestsellerDoc.id}:`, err);
        error++;
      }
    }
    
    console.log('\n='.repeat(50));
    console.log('Bestsellers update summary:');
    console.log(`Total processed: ${success + error}`);
    console.log(`Successfully updated: ${success}`);
    console.log(`Errors: ${error}`);
    
  } catch (error) {
    console.error('Error updating bestsellers structure:', error);
  }
}

// Run the update
updateBestsellersStructure()
  .then(() => {
    console.log('\nBestsellers structure update completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Failed to update bestsellers structure:', error);
    process.exit(1);
  });
