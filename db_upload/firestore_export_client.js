import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import fs from 'fs';
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
const auth = getAuth(app);

const outputFile = 'firestore_categories_export.txt';
let output = '';

// Function to add text to output
function addToOutput(text) {
  output += text + '\n';
  console.log(text);
}

// Recursive function to explore documents and subcollections
async function exploreCollection(collectionRef, collectionPath, indentLevel = 0) {
  const indent = '  '.repeat(indentLevel);
  
  try {
    const snapshot = await getDocs(collectionRef);
    
    if (snapshot.empty) {
      addToOutput(`${indent}This collection is empty.`);
      return;
    }
    
    for (const doc of snapshot.docs) {
      addToOutput(`${indent}Document: ${doc.id}`);
      
      // Get document data
      const docData = doc.data();
      if (docData) {
        Object.entries(docData).forEach(([key, value]) => {
          addToOutput(`${indent}  ${key}: ${typeof value === 'object' ? JSON.stringify(value) : value}`);
        });
      }
      
      // Check for 'items' subcollection specifically since client SDK doesn't have listCollections
      const itemsPath = `${collectionPath}/${doc.id}/items`;
      const itemsCollectionRef = collection(db, itemsPath);
      
      try {
        const itemsSnapshot = await getDocs(itemsCollectionRef);
        
        if (!itemsSnapshot.empty) {
          addToOutput(`${indent}  Subcollection: items`);
          await exploreCollection(itemsCollectionRef, itemsPath, indentLevel + 2);
        }
      } catch (error) {
        // If items subcollection doesn't exist, this error will be caught
        // We'll ignore it as it's expected behavior
      }
      
      addToOutput(''); // Add empty line between documents
    }
  } catch (error) {
    console.error(`Error exploring collection: ${error}`);
    addToOutput(`${indent}Error: ${error.message}`);
  }
}

// Main function to start the export
async function exportFirestoreData() {
  try {
    addToOutput('=== FIRESTORE EXPORT ===');
    addToOutput(`Export started at: ${new Date().toISOString()}`);
    addToOutput('');
    
    // Add authentication here if needed
    // await signInWithEmailAndPassword(auth, 'your-email@example.com', 'your-password');
    
    addToOutput('Categories Collection:');
    addToOutput('=====================');
    
    const categoriesRef = collection(db, 'categories');
    await exploreCollection(categoriesRef, 'categories');
    
    // Save to file
    fs.writeFileSync(outputFile, output);
    console.log(`Export complete! Data saved to ${outputFile}`);
    
  } catch (error) {
    console.error('Error during export:', error);
  } finally {
    process.exit();
  }
}

exportFirestoreData();
