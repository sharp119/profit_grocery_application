import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs, updateDoc } from 'firebase/firestore';
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

// Product templates for different snacks & drinks categories
const productTemplates = {
  chips_namkeen: [
    {
      name: "Classic Salted Potato Chips",
      description: "Crispy potato chips with perfect salt seasoning",
      inStock: true,
      price: 40,
      quantity: 100,
      weight: "100 g",
      brand: "Lay's",
      ingredients: "Potatoes, vegetable oil, salt",
      nutritionalInfo: "Calories: 540 per 100g, Fat: 34g",
      sku: "CHP001",
      productType: "Chips"
    },
    {
      name: "Aloo Bhujia",
      description: "Traditional spicy potato and gram flour snack",
      inStock: true,
      price: 85,
      quantity: 60,
      weight: "200 g",
      brand: "Haldiram's",
      ingredients: "Potato, gram flour, vegetable oil, spices",
      nutritionalInfo: "Calories: 557 per 100g, Protein: 12g",
      sku: "NMK001",
      productType: "Namkeen"
    },
    {
      name: "Cheese Nachos",
      description: "Corn chips with cheese flavor",
      inStock: true,
      price: 60,
      quantity: 70,
      weight: "150 g",
      brand: "Doritos",
      ingredients: "Corn, vegetable oil, cheese powder",
      nutritionalInfo: "Calories: 492 per 100g, Fat: 23g",
      sku: "CHP002",
      productType: "Chips"
    },
    {
      name: "Mixture",
      description: "Traditional South Indian savory mix",
      inStock: true,
      price: 95,
      quantity: 45,
      weight: "250 g",
      brand: "MTR",
      ingredients: "Gram flour, peanuts, rice flakes, spices",
      nutritionalInfo: "Calories: 532 per 100g, Protein: 15g",
      sku: "NMK002",
      productType: "Namkeen"
    },
    {
      name: "Banana Chips",
      description: "Crispy banana chips with salt and spices",
      inStock: true,
      price: 70,
      quantity: 55,
      weight: "200 g",
      brand: "Yellow",
      ingredients: "Banana, vegetable oil, salt, spices",
      nutritionalInfo: "Calories: 519 per 100g, Carbs: 58g",
      sku: "CHP003",
      productType: "Chips"
    }
  ],
  drinks_juices: [
    {
      name: "Mixed Fruit Juice",
      description: "Real fruit juice with no added preservatives",
      inStock: true,
      price: 99,
      quantity: 80,
      weight: "1 L",
      brand: "Real",
      ingredients: "Mixed fruit pulp, water, sugar",
      nutritionalInfo: "Calories: 50 per 100ml, Vitamin C: 100% DV",
      sku: "JUC001",
      productType: "Juice"
    },
    {
      name: "Mango Lassi",
      description: "Traditional Indian yogurt drink with mango",
      inStock: true,
      price: 45,
      quantity: 90,
      weight: "200 ml",
      brand: "Amul",
      ingredients: "Milk, mango pulp, sugar, cultures",
      nutritionalInfo: "Calories: 98 per serving, Protein: 3g",
      sku: "DRK001",
      productType: "Lassi"
    },
    {
      name: "Lemon Iced Tea",
      description: "Refreshing iced tea with lemon flavor",
      inStock: true,
      price: 35,
      quantity: 100,
      weight: "250 ml",
      brand: "Nestea",
      ingredients: "Water, tea extract, lemon, sugar",
      nutritionalInfo: "Calories: 70 per serving, Sugar: 17g",
      sku: "DRK002",
      productType: "Iced Tea"
    },
    {
      name: "Orange Juice",
      description: "100% orange juice with no added sugar",
      inStock: true,
      price: 110,
      quantity: 50,
      weight: "1 L",
      brand: "Tropicana",
      ingredients: "100% Orange juice",
      nutritionalInfo: "Calories: 45 per 100ml, Vitamin C: 140% DV",
      sku: "JUC002",
      productType: "Juice"
    },
    {
      name: "Coconut Water",
      description: "Natural tender coconut water",
      inStock: true,
      price: 40,
      quantity: 75,
      weight: "200 ml",
      brand: "Paper Boat",
      ingredients: "100% Coconut water",
      nutritionalInfo: "Calories: 19 per 100ml, Potassium: 5% DV",
      sku: "DRK003",
      productType: "Coconut Water"
    }
  ],
  energy_drinks: [
    {
      name: "Energy Drink - Original",
      description: "Provides instant energy and alertness",
      inStock: true,
      price: 95,
      quantity: 60,
      weight: "250 ml",
      brand: "Red Bull",
      ingredients: "Caffeine, taurine, B-vitamins, sugar",
      nutritionalInfo: "Calories: 110 per can, Caffeine: 80mg",
      sku: "ENG001",
      productType: "Energy Drink"
    },
    {
      name: "Sports Drink - Blue",
      description: "Electrolyte drink for sports recovery",
      inStock: true,
      price: 40,
      quantity: 80,
      weight: "500 ml",
      brand: "Gatorade",
      ingredients: "Water, electrolytes, sugar, flavorings",
      nutritionalInfo: "Calories: 80 per 240ml, Sodium: 110mg",
      sku: "ENG002",
      productType: "Sports Drink"
    },
    {
      name: "Power Shots",
      description: "Concentrated energy boost in small size",
      inStock: true,
      price: 65,
      quantity: 100,
      weight: "60 ml",
      brand: "Monster",
      ingredients: "Caffeine, vitamins, amino acids",
      nutritionalInfo: "Calories: 50 per shot, Caffeine: 150mg",
      sku: "ENG003",
      productType: "Energy Shot"
    },
    {
      name: "Protein Energy Drink",
      description: "Energy drink with added protein",
      inStock: true,
      price: 120,
      quantity: 45,
      weight: "330 ml",
      brand: "Prime",
      ingredients: "Whey protein, caffeine, vitamins",
      nutritionalInfo: "Calories: 130 per can, Protein: 10g",
      sku: "ENG004",
      productType: "Protein Energy"
    },
    {
      name: "Natural Energy Drink",
      description: "Energy drink with natural ingredients",
      inStock: true,
      price: 85,
      quantity: 55,
      weight: "300 ml",
      brand: "Organic Energy",
      ingredients: "Green tea extract, guarana, ginseng",
      nutritionalInfo: "Calories: 90 per serving, Caffeine: 95mg",
      sku: "ENG005",
      productType: "Natural Energy"
    }
  ],
  ice_cream: [
    {
      name: "Vanilla Ice Cream",
      description: "Classic vanilla flavored ice cream",
      inStock: true,
      price: 149,
      quantity: 40,
      weight: "750 ml",
      brand: "Amul",
      ingredients: "Milk, cream, sugar, vanilla",
      nutritionalInfo: "Calories: 207 per 100g, Fat: 11g",
      sku: "ICE001",
      productType: "Ice Cream"
    },
    {
      name: "Chocolate Fudge Brownie",
      description: "Rich chocolate ice cream with brownie pieces",
      inStock: true,
      price: 299,
      quantity: 25,
      weight: "500 ml",
      brand: "Baskin Robbins",
      ingredients: "Cream, chocolate, brownie pieces",
      nutritionalInfo: "Calories: 270 per 100g, Sugar: 26g",
      sku: "ICE002",
      productType: "Ice Cream"
    },
    {
      name: "Kulfi Sticks",
      description: "Traditional Indian frozen dessert",
      inStock: true,
      price: 120,
      quantity: 60,
      weight: "4 x 50 ml",
      brand: "Mother Dairy",
      ingredients: "Milk, sugar, nuts, cardamom",
      nutritionalInfo: "Calories: 90 per stick, Fat: 5g",
      sku: "ICE003",
      productType: "Kulfi"
    },
    {
      name: "Fruit Sorbet Mix",
      description: "Assorted fruit sorbets with real fruit",
      inStock: true,
      price: 249,
      quantity: 30,
      weight: "500 ml",
      brand: "Natural's",
      ingredients: "Fruit pulp, sugar, water",
      nutritionalInfo: "Calories: 120 per 100g, Fat: 0g",
      sku: "ICE004",
      productType: "Sorbet"
    },
    {
      name: "Sugar-Free Vanilla",
      description: "No sugar added vanilla ice cream",
      inStock: true,
      price: 199,
      quantity: 35,
      weight: "500 ml",
      brand: "Vadilal",
      ingredients: "Milk, sweeteners, vanilla extract",
      nutritionalInfo: "Calories: 130 per 100g, Sugar: 0g",
      sku: "ICE005",
      productType: "Ice Cream"
    }
  ],
  paan_corner: [
    {
      name: "Meetha Paan",
      description: "Sweet betel leaf preparation with gulkand",
      inStock: true,
      price: 30,
      quantity: 100,
      weight: "1 piece",
      brand: "Traditional",
      ingredients: "Betel leaf, gulkand, fennel, cardamom",
      nutritionalInfo: "Calories: 40 per piece",
      sku: "PAN001",
      productType: "Paan"
    },
    {
      name: "Gulkand",
      description: "Rose petal preserve for paan and desserts",
      inStock: true,
      price: 149,
      quantity: 40,
      weight: "400 g",
      brand: "Hamdard",
      ingredients: "Rose petals, sugar",
      nutritionalInfo: "Calories: 220 per 100g",
      sku: "PAN002",
      productType: "Paan Ingredient"
    },
    {
      name: "Supari Mix",
      description: "Assorted betel nut preparations",
      inStock: true,
      price: 99,
      quantity: 60,
      weight: "200 g",
      brand: "Paan Bahar",
      ingredients: "Betel nut, flavors, sugar coating",
      nutritionalInfo: "Calories: 70 per serving",
      sku: "PAN003",
      productType: "Supari"
    },
    {
      name: "Mukhwas Mix",
      description: "After-meal mouth freshener mix",
      inStock: true,
      price: 65,
      quantity: 80,
      weight: "200 g",
      brand: "Everest",
      ingredients: "Fennel, sesame, coriander seeds",
      nutritionalInfo: "Calories: 300 per 100g",
      sku: "PAN004",
      productType: "Mukhwas"
    },
    {
      name: "Chocolate Paan",
      description: "Modern fusion of paan with chocolate",
      inStock: true,
      price: 45,
      quantity: 50,
      weight: "1 piece",
      brand: "Fusion Paan",
      ingredients: "Betel leaf, chocolate, coconut",
      nutritionalInfo: "Calories: 80 per piece",
      sku: "PAN005",
      productType: "Paan"
    }
  ],
  soft_drinks: [
    {
      name: "Cola",
      description: "Classic cola flavor soft drink",
      inStock: true,
      price: 40,
      quantity: 150,
      weight: "750 ml",
      brand: "Coca-Cola",
      ingredients: "Carbonated water, sugar, caffeine",
      nutritionalInfo: "Calories: 140 per 330ml, Sugar: 35g",
      sku: "SFT001",
      productType: "Soft Drink"
    },
    {
      name: "Lemon Soda",
      description: "Refreshing lemon-lime flavored soda",
      inStock: true,
      price: 35,
      quantity: 120,
      weight: "750 ml",
      brand: "Sprite",
      ingredients: "Carbonated water, sugar, citric acid",
      nutritionalInfo: "Calories: 130 per 330ml, Sugar: 33g",
      sku: "SFT002",
      productType: "Soft Drink"
    },
    {
      name: "Orange Soda",
      description: "Orange flavored carbonated drink",
      inStock: true,
      price: 35,
      quantity: 100,
      weight: "600 ml",
      brand: "Mirinda",
      ingredients: "Carbonated water, sugar, orange flavor",
      nutritionalInfo: "Calories: 160 per 330ml, Sugar: 40g",
      sku: "SFT003",
      productType: "Soft Drink"
    },
    {
      name: "Diet Cola",
      description: "Zero calorie cola",
      inStock: true,
      price: 45,
      quantity: 60,
      weight: "300 ml",
      brand: "Diet Coke",
      ingredients: "Carbonated water, aspartame, caffeine",
      nutritionalInfo: "Calories: 0 per serving, Sugar: 0g",
      sku: "SFT004",
      productType: "Soft Drink"
    },
    {
      name: "Jeera Soda",
      description: "Indian spice flavored carbonated drink",
      inStock: true,
      price: 30,
      quantity: 90,
      weight: "250 ml",
      brand: "Bisleri",
      ingredients: "Carbonated water, jeera, black salt",
      nutritionalInfo: "Calories: 60 per 250ml, Sodium: 120mg",
      sku: "SFT005",
      productType: "Soft Drink"
    }
  ],
  sweets_chocolates: [
    {
      name: "Milk Chocolate Bar",
      description: "Classic milk chocolate with smooth texture",
      inStock: true,
      price: 40,
      quantity: 200,
      weight: "50 g",
      brand: "Cadbury Dairy Milk",
      ingredients: "Milk, sugar, cocoa butter, cocoa mass",
      nutritionalInfo: "Calories: 240 per bar, Sugar: 25g",
      sku: "CHC001",
      productType: "Chocolate"
    },
    {
      name: "Gulab Jamun",
      description: "Soft milk dumplings in sugar syrup",
      inStock: true,
      price: 299,
      quantity: 30,
      weight: "1 kg",
      brand: "Haldiram's",
      ingredients: "Milk solids, sugar, rose water",
      nutritionalInfo: "Calories: 375 per 100g, Sugar: 55g",
      sku: "SWT001",
      productType: "Indian Sweet"
    },
    {
      name: "Assorted Toffees",
      description: "Mix of mango, orange, and strawberry toffees",
      inStock: true,
      price: 99,
      quantity: 80,
      weight: "500 g",
      brand: "Parle Melody",
      ingredients: "Sugar, liquid glucose, flavors",
      nutritionalInfo: "Calories: 400 per 100g",
      sku: "SWT002",
      productType: "Candy"
    },
    {
      name: "Dark Chocolate",
      description: "70% cocoa dark chocolate bar",
      inStock: true,
      price: 120,
      quantity: 50,
      weight: "100 g",
      brand: "Amul Dark",
      ingredients: "Cocoa mass, sugar, cocoa butter",
      nutritionalInfo: "Calories: 530 per 100g, Cocoa: 70%",
      sku: "CHC002",
      productType: "Chocolate"
    },
    {
      name: "Soan Papdi",
      description: "Flaky Indian sweet made with gram flour",
      inStock: true,
      price: 199,
      quantity: 40,
      weight: "500 g",
      brand: "Bikaji",
      ingredients: "Gram flour, sugar, ghee, cardamom",
      nutritionalInfo: "Calories: 420 per 100g, Fat: 20g",
      sku: "SWT003",
      productType: "Indian Sweet"
    }
  ],
  tea_coffee_milk: [
    {
      name: "Masala Tea",
      description: "Aromatic black tea with Indian spices",
      inStock: true,
      price: 249,
      quantity: 70,
      weight: "250 g",
      brand: "Tata Tea Gold",
      ingredients: "Black tea, cardamom, ginger, cinnamon",
      nutritionalInfo: "Calories: 2 per cup (without milk/sugar)",
      sku: "TEA001",
      productType: "Tea"
    },
    {
      name: "Instant Coffee",
      description: "Freeze dried coffee granules for quick preparation",
      inStock: true,
      price: 299,
      quantity: 50,
      weight: "200 g",
      brand: "Nescafe Classic",
      ingredients: "100% Coffee",
      nutritionalInfo: "Calories: 4 per cup (black)",
      sku: "COF001",
      productType: "Coffee"
    },
    {
      name: "Green Tea",
      description: "Natural green tea for health benefits",
      inStock: true,
      price: 199,
      quantity: 60,
      weight: "100 bags",
      brand: "Lipton",
      ingredients: "100% Green tea leaves",
      nutritionalInfo: "Calories: 0 per cup",
      sku: "TEA002",
      productType: "Tea"
    },
    {
      name: "Chocolate Malt Drink",
      description: "Nutritious chocolate flavored health drink",
      inStock: true,
      price: 349,
      quantity: 40,
      weight: "500 g",
      brand: "Bournvita",
      ingredients: "Malt extract, cocoa, sugar, vitamins",
      nutritionalInfo: "Calories: 385 per 100g, Protein: 7g",
      sku: "MLK001",
      productType: "Health Drink"
    },
    {
      name: "Filter Coffee Powder",
      description: "Authentic South Indian filter coffee blend",
      inStock: true,
      price: 180,
      quantity: 45,
      weight: "200 g",
      brand: "Bru",
      ingredients: "Coffee beans (80%), chicory (20%)",
      nutritionalInfo: "Calories: 5 per cup (black)",
      sku: "COF002",
      productType: "Coffee"
    }
  ]
};

async function addProductsToCategory(categoryGroup, categoryItem) {
  const products = productTemplates[categoryItem] || [];
  
  if (products.length === 0) {
    console.log(`No products defined for ${categoryItem}`);
    return;
  }
  
  console.log(`Adding products to ${categoryGroup}/${categoryItem}`);
  
  for (const product of products) {
    try {
      // Add the product to the Firestore collection
      const docRef = await addDoc(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'), {
        ...product,
        createdAt: new Date(),
        updatedAt: new Date(),
        categoryGroup: categoryGroup,
        categoryItem: categoryItem
      });
      
      // Generate the image path
      const imagePath = `gs://profit-grocery.firebasestorage.app/products/${categoryGroup}/${categoryItem}/${docRef.id}/image.png`;
      
      // Update the document with the image path
      await updateDoc(docRef, {
        imagePath: imagePath
      });
      
      console.log(`  ✓ Added: ${product.name} (ID: ${docRef.id})`);
      console.log(`    Image path: ${imagePath}`);
      
    } catch (error) {
      console.error(`  ✗ Error adding ${product.name}:`, error);
    }
  }
}

async function populateSnacksDrinksCategory() {
  const categoryGroup = 'snacks_drinks';
  
  console.log(`\nPopulating products for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'categories', categoryGroup, 'items'));
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      await addProductsToCategory(categoryGroup, categoryItem);
    }
    
    console.log('\n='.repeat(50));
    console.log('Finished populating products for', categoryGroup);
    
  } catch (error) {
    console.error('Error populating category:', error);
  }
}

// Run the script
populateSnacksDrinksCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
