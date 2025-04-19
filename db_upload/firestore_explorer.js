import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, getDoc } from 'firebase/firestore';
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

const outputFile = 'categories_structure.txt';
let output = '';

// Function to add text to output
function addToOutput(text) {
  output += text + '\n';
  console.log(text);
}

// Function to explore categories and their items
async function exploreCategoriesStructure() {
  try {
    addToOutput('=== FIRESTORE STRUCTURE EXPLORER ===');
    addToOutput(`Export started at: ${new Date().toISOString()}`);
    addToOutput('');
    
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    
    addToOutput('Categories Collection:');
    addToOutput('=====================');
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      addToOutput(`\nCategory Document: ${categoryDoc.id}`);
      
      // Print category data
      const categoryData = categoryDoc.data();
      Object.entries(categoryData).forEach(([key, value]) => {
        addToOutput(`  ${key}: ${typeof value === 'object' ? JSON.stringify(value) : value}`);
      });
      
      // Check for items subcollection
      const itemsSnapshot = await getDocs(collection(db, 'categories', categoryDoc.id, 'items'));
      
      if (!itemsSnapshot.empty) {
        addToOutput('  Subcollection: items');
        
        for (const itemDoc of itemsSnapshot.docs) {
          addToOutput(`    Document ID: ${itemDoc.id}`);
          
          const itemData = itemDoc.data();
          Object.entries(itemData).forEach(([key, value]) => {
            addToOutput(`      ${key}: ${typeof value === 'object' ? JSON.stringify(value) : value}`);
          });
          
          addToOutput(''); // Add spacing between items
        }
      } else {
        addToOutput('  No items subcollection found');
      }
      
      addToOutput(''); // Add spacing between categories
    }
    
    // Save to file
    fs.writeFileSync(outputFile, output);
    console.log(`Export complete! Data saved to ${outputFile}`);
    
  } catch (error) {
    console.error('Error during export:', error);
    addToOutput(`Error: ${error.message}`);
    
    // Save error to file as well
    fs.writeFileSync(outputFile, output);
  }
}

// Run the explorer
exploreCategoriesStructure().then(() => {
  console.log('Exploration completed.');
  process.exit(0);
}).catch((error) => {
  console.error('Failed to explore structure:', error);
  process.exit(1);
});
