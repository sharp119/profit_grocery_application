import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Initialize Firebase Admin SDK
const serviceAccount = {
  type: "service_account",
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
};

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL
  });
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Error initializing Firebase Admin:', error);
  process.exit(1);
}

const db = admin.firestore();
const outputFile = 'firestore_categories_export.txt';
let output = '';

// Function to add text to output
function addToOutput(text) {
  output += text + '\n';
  console.log(text);
}

// Recursive function to explore documents and subcollections
async function exploreCollection(collectionRef, indentLevel = 0) {
  const indent = '  '.repeat(indentLevel);
  
  try {
    const snapshot = await collectionRef.get();
    
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
      
      // Get subcollections
      const subcollections = await doc.ref.listCollections();
      
      for (const subcollection of subcollections) {
        addToOutput(`${indent}  Subcollection: ${subcollection.id}`);
        await exploreCollection(subcollection, indentLevel + 2);
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
    
    addToOutput('Categories Collection:');
    addToOutput('=====================');
    
    const categoriesRef = db.collection('categories');
    await exploreCollection(categoriesRef);
    
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
