import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

console.log('🔧 Testing Firebase Connection...');
console.log('='.repeat(40));

// Check if environment variables are loaded
console.log('📋 Environment Variables Check:');
console.log(`  FIREBASE_PROJECT_ID: ${process.env.FIREBASE_PROJECT_ID ? '✅ Found' : '❌ Missing'}`);
console.log(`  FIREBASE_API_KEY: ${process.env.FIREBASE_API_KEY ? '✅ Found' : '❌ Missing'}`);
console.log(`  FIREBASE_AUTH_DOMAIN: ${process.env.FIREBASE_AUTH_DOMAIN ? '✅ Found' : '❌ Missing'}`);

if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_API_KEY) {
  console.error('❌ Missing required Firebase environment variables!');
  console.log('📝 Make sure your .env file exists and contains all required Firebase config');
  process.exit(1);
}

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

try {
  console.log('\n🔥 Initializing Firebase...');
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);
  console.log('✅ Firebase initialized successfully');

  console.log('\n📊 Testing Firestore Connection...');
  
  // Test 1: Check if products collection exists
  console.log('🔍 Checking products collection...');
  const productsRef = collection(db, 'products');
  const productsSnapshot = await getDocs(productsRef);
  
  if (productsSnapshot.empty) {
    console.log('⚠️  Products collection is empty or doesn\'t exist');
  } else {
    console.log(`✅ Products collection found with ${productsSnapshot.docs.length} category groups:`);
    productsSnapshot.docs.forEach(doc => {
      console.log(`  - ${doc.id}`);
    });
  }

  // Test 2: Check categories collection (fallback)
  console.log('\n🔍 Checking categories collection...');
  const categoriesRef = collection(db, 'categories');
  const categoriesSnapshot = await getDocs(categoriesRef);
  
  if (categoriesSnapshot.empty) {
    console.log('⚠️  Categories collection is empty or doesn\'t exist');
  } else {
    console.log(`✅ Categories collection found with ${categoriesSnapshot.docs.length} documents:`);
    categoriesSnapshot.docs.forEach(doc => {
      console.log(`  - ${doc.id}`);
    });
  }

  console.log('\n🎉 Firebase connection test completed!');
  
} catch (error) {
  console.error('\n❌ Firebase connection failed:');
  console.error('Error:', error.message);
  console.error('Code:', error.code);
  
  if (error.code === 'auth/invalid-api-key') {
    console.log('\n💡 Tip: Check your FIREBASE_API_KEY in .env file');
  } else if (error.code === 'permission-denied') {
    console.log('\n💡 Tip: Check your Firestore security rules');
  } else if (error.message.includes('network')) {
    console.log('\n💡 Tip: Check your internet connection');
  }
}

process.exit(0);
