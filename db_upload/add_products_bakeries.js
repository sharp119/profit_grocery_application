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

// Product templates for different bakery categories
const productTemplates = {
  bakery_snacks: [
    {
      name: "Butter Garlic Bread Sticks",
      description: "Crispy bread sticks with rich butter and garlic flavor, perfect for snacking or with soup",
      inStock: true,
      price: 60,
      quantity: 20,
      weight: "200g",
      brand: "Fresh Bakery",
      ingredients: "Wheat flour, butter, garlic, yeast, salt",
      nutritionalInfo: "Calories: 150 per serving, Protein: 4g, Carbs: 25g, Fat: 4g",
      sku: "BKRY001",
      productType: "Bakery Snacks"
    },
    {
      name: "Chocolate Chip Cookies",
      description: "Soft and chewy cookies loaded with premium chocolate chips",
      inStock: true,
      price: 120,
      quantity: 15,
      weight: "250g",
      brand: "Cookie Master",
      ingredients: "Refined flour, chocolate chips, butter, sugar, eggs",
      nutritionalInfo: "Calories: 200 per serving, Protein: 3g, Carbs: 30g, Fat: 8g",
      sku: "BKRY002",
      productType: "Bakery Snacks"
    },
    {
      name: "Mini Cheese Croissants",
      description: "Flaky and buttery croissants filled with rich cheese",
      inStock: false,
      price: 150,
      quantity: 0,
      weight: "300g",
      brand: "French Corner",
      ingredients: "Wheat flour, butter, cheese, yeast, salt",
      nutritionalInfo: "Calories: 250 per piece, Protein: 7g, Carbs: 28g, Fat: 12g",
      sku: "BKRY003",
      productType: "Bakery Snacks"
    },
    {
      name: "Spinach & Corn Puffs",
      description: "Light and crispy puff pastries filled with spinach and corn",
      inStock: true,
      price: 80,
      quantity: 25,
      weight: "180g",
      brand: "Veggie Delights",
      ingredients: "Puff pastry, spinach, corn, cream, spices",
      nutritionalInfo: "Calories: 120 per serving, Protein: 3g, Carbs: 20g, Fat: 5g",
      sku: "BKRY004",
      productType: "Bakery Snacks"
    }
  ],
  buns_pavs: [
    {
      name: "Classic Pav Bread",
      description: "Soft and fluffy pav bread, perfect for making pav bhaji",
      inStock: true,
      price: 40,
      quantity: 30,
      weight: "400g",
      brand: "Mumbai Bakery",
      ingredients: "Wheat flour, yeast, sugar, salt, milk",
      nutritionalInfo: "Calories: 90 per bun, Protein: 3g, Carbs: 18g, Fat: 1g",
      sku: "BNS001",
      productType: "Buns & Pavs"
    },
    {
      name: "Whole Wheat Burger Buns",
      description: "Healthy whole wheat burger buns with sesame seeds on top",
      inStock: true,
      price: 55,
      quantity: 20,
      weight: "360g",
      brand: "Health First Bakery",
      ingredients: "Whole wheat flour, yeast, olive oil, sesame seeds",
      nutritionalInfo: "Calories: 120 per bun, Protein: 5g, Carbs: 22g, Fat: 2g",
      sku: "BNS002",
      productType: "Buns & Pavs"
    },
    {
      name: "Garlic Bread Buns",
      description: "Soft buns infused with garlic and herb flavors",
      inStock: true,
      price: 65,
      quantity: 15,
      weight: "320g",
      brand: "Garlic Heaven",
      ingredients: "Refined flour, fresh garlic, herbs, butter",
      nutritionalInfo: "Calories: 110 per bun, Protein: 4g, Carbs: 20g, Fat: 3g",
      sku: "BNS003",
      productType: "Buns & Pavs"
    },
    {
      name: "Multigrain Hot Dog Buns",
      description: "Nutritious multigrain buns perfect for hot dogs",
      inStock: true,
      price: 70,
      quantity: 18,
      weight: "350g",
      brand: "Grains & More",
      ingredients: "Multiple grains, seeds, honey, yeast",
      nutritionalInfo: "Calories: 130 per bun, Protein: 6g, Carbs: 24g, Fat: 2g",
      sku: "BNS004",
      productType: "Buns & Pavs"
    }
  ],
  cakes_pastries: [
    {
      name: "Black Forest Cake",
      description: "Classic black forest cake with layers of chocolate sponge, cherry filling, and whipped cream",
      inStock: true,
      price: 499,
      quantity: 5,
      weight: "500g",
      brand: "Cake Studio",
      ingredients: "Chocolate sponge, whipped cream, cherries, chocolate shavings",
      nutritionalInfo: "Calories: 350 per slice, Protein: 4g, Carbs: 45g, Fat: 18g",
      sku: "CKE001",
      productType: "Cakes"
    },
    {
      name: "Strawberry Pastry",
      description: "Light and fluffy pastry with fresh strawberry cream filling",
      inStock: true,
      price: 80,
      quantity: 12,
      weight: "100g",
      brand: "Pastry Paradise",
      ingredients: "Sponge cake, strawberry cream, fresh strawberries",
      nutritionalInfo: "Calories: 250 per piece, Protein: 3g, Carbs: 35g, Fat: 12g",
      sku: "CKE002",
      productType: "Pastries"
    },
    {
      name: "Chocolate Truffle Pastry",
      description: "Rich chocolate pastry with smooth truffle filling and chocolate ganache",
      inStock: true,
      price: 90,
      quantity: 10,
      weight: "120g",
      brand: "Choco Heaven",
      ingredients: "Chocolate sponge, chocolate truffle, dark chocolate ganache",
      nutritionalInfo: "Calories: 300 per piece, Protein: 4g, Carbs: 38g, Fat: 15g",
      sku: "CKE003",
      productType: "Pastries"
    },
    {
      name: "Red Velvet Cake",
      description: "Moist red velvet cake with cream cheese frosting",
      inStock: false,
      price: 599,
      quantity: 0,
      weight: "600g",
      brand: "Velvet Delight",
      ingredients: "Red velvet sponge, cream cheese frosting, cocoa powder",
      nutritionalInfo: "Calories: 400 per slice, Protein: 5g, Carbs: 55g, Fat: 20g",
      sku: "CKE004",
      productType: "Cakes"
    }
  ],
  cookies: [
    {
      name: "Almond Biscotti",
      description: "Crunchy Italian cookies with whole almonds, perfect for dipping in coffee",
      inStock: true,
      price: 180,
      quantity: 20,
      weight: "250g",
      brand: "Italian Treats",
      ingredients: "Almond, flour, sugar, eggs, vanilla",
      nutritionalInfo: "Calories: 80 per piece, Protein: 3g, Carbs: 12g, Fat: 3g",
      sku: "COK001",
      productType: "Cookies"
    },
    {
      name: "Oatmeal Raisin Cookies",
      description: "Traditional oatmeal cookies loaded with plump raisins",
      inStock: true,
      price: 120,
      quantity: 25,
      weight: "300g",
      brand: "Grandma's Kitchen",
      ingredients: "Oats, raisins, flour, butter, brown sugar",
      nutritionalInfo: "Calories: 110 per cookie, Protein: 2g, Carbs: 18g, Fat: 4g",
      sku: "COK002",
      productType: "Cookies"
    },
    {
      name: "Double Chocolate Cookies",
      description: "Rich chocolate cookies with extra chocolate chunks",
      inStock: true,
      price: 150,
      quantity: 18,
      weight: "280g",
      brand: "Choco Delights",
      ingredients: "Dark chocolate, cocoa powder, flour, butter",
      nutritionalInfo: "Calories: 150 per cookie, Protein: 3g, Carbs: 22g, Fat: 7g",
      sku: "COK003",
      productType: "Cookies"
    },
    {
      name: "Butter Shortbread",
      description: "Classic Scottish shortbread made with pure butter",
      inStock: true,
      price: 140,
      quantity: 15,
      weight: "200g",
      brand: "Scottish Bakery",
      ingredients: "Butter, flour, sugar, salt",
      nutritionalInfo: "Calories: 130 per piece, Protein: 2g, Carbs: 16g, Fat: 8g",
      sku: "COK004",
      productType: "Cookies"
    }
  ],
  cream_biscuits: [
    {
      name: "Vanilla Cream Sandwich Biscuits",
      description: "Crispy biscuits with smooth vanilla cream filling",
      inStock: true,
      price: 35,
      quantity: 50,
      weight: "150g",
      brand: "Cream Delight",
      ingredients: "Wheat flour, sugar, vanilla cream, vegetable oil",
      nutritionalInfo: "Calories: 75 per serving, Protein: 1g, Carbs: 12g, Fat: 3g",
      sku: "CBT001",
      productType: "Cream Biscuits"
    },
    {
      name: "Chocolate Cream Filled Biscuits",
      description: "Dark chocolate biscuits with rich chocolate cream center",
      inStock: true,
      price: 40,
      quantity: 45,
      weight: "200g",
      brand: "Choco Treats",
      ingredients: "Cocoa powder, flour, chocolate cream, sugar",
      nutritionalInfo: "Calories: 85 per serving, Protein: 1g, Carbs: 14g, Fat: 3.5g",
      sku: "CBT002",
      productType: "Cream Biscuits"
    },
    {
      name: "Strawberry Cream Biscuits",
      description: "Light biscuits with delightful strawberry cream filling",
      inStock: true,
      price: 45,
      quantity: 30,
      weight: "180g",
      brand: "Berry Bliss",
      ingredients: "Wheat flour, strawberry flavor, cream, sugar",
      nutritionalInfo: "Calories: 70 per serving, Protein: 1g, Carbs: 11g, Fat: 3g",
      sku: "CBT003",
      productType: "Cream Biscuits"
    },
    {
      name: "Coffee Cream Sandwich",
      description: "Coffee-flavored biscuits with mocha cream filling",
      inStock: false,
      price: 50,
      quantity: 0,
      weight: "160g",
      brand: "Café Bakers",
      ingredients: "Coffee powder, wheat flour, cream, sugar",
      nutritionalInfo: "Calories: 80 per serving, Protein: 1g, Carbs: 13g, Fat: 3.5g",
      sku: "CBT004",
      productType: "Cream Biscuits"
    }
  ],
  premium_cookies: [
    {
      name: "Belgian Chocolate Chunk Cookies",
      description: "Premium cookies made with authentic Belgian chocolate chunks",
      inStock: true,
      price: 299,
      quantity: 10,
      weight: "200g",
      brand: "Luxury Bakes",
      ingredients: "Belgian chocolate, premium butter, organic flour",
      nutritionalInfo: "Calories: 180 per cookie, Protein: 3g, Carbs: 25g, Fat: 9g",
      sku: "PCK001",
      productType: "Premium Cookies"
    },
    {
      name: "Macadamia Nut Cookies",
      description: "Buttery cookies loaded with premium macadamia nuts",
      inStock: true,
      price: 350,
      quantity: 8,
      weight: "180g",
      brand: "Nutty Delights",
      ingredients: "Macadamia nuts, butter, flour, brown sugar",
      nutritionalInfo: "Calories: 170 per cookie, Protein: 3g, Carbs: 20g, Fat: 10g",
      sku: "PCK002",
      productType: "Premium Cookies"
    },
    {
      name: "Pistachio Rose Shortbread",
      description: "Delicate shortbread cookies with pistachio and rose water",
      inStock: true,
      price: 320,
      quantity: 12,
      weight: "150g",
      brand: "Gourmet Bakes",
      ingredients: "Pistachios, rose water, butter, flour, sugar",
      nutritionalInfo: "Calories: 140 per cookie, Protein: 3g, Carbs: 18g, Fat: 7g",
      sku: "PCK003",
      productType: "Premium Cookies"
    },
    {
      name: "Salted Caramel Chocolate Cookies",
      description: "Rich chocolate cookies with gooey salted caramel center",
      inStock: true,
      price: 280,
      quantity: 15,
      weight: "220g",
      brand: "Sweet Sensations",
      ingredients: "Dark chocolate, salted caramel, flour, eggs",
      nutritionalInfo: "Calories: 190 per cookie, Protein: 3g, Carbs: 26g, Fat: 10g",
      sku: "PCK004",
      productType: "Premium Cookies"
    }
  ],
  rusk_khari: [
    {
      name: "Classic Wheat Rusk",
      description: "Crispy wheat rusk perfect for tea time",
      inStock: true,
      price: 45,
      quantity: 40,
      weight: "300g",
      brand: "Tea Time",
      ingredients: "Whole wheat flour, yeast, sugar, salt",
      nutritionalInfo: "Calories: 40 per piece, Protein: 1g, Carbs: 8g, Fat: 0.5g",
      sku: "RSK001",
      productType: "Rusk"
    },
    {
      name: "Butter Khari Biscuit",
      description: "Flaky and crispy khari biscuits with rich butter flavor",
      inStock: true,
      price: 60,
      quantity: 35,
      weight: "250g",
      brand: "Khari King",
      ingredients: "Refined flour, butter, salt",
      nutritionalInfo: "Calories: 35 per piece, Protein: 1g, Carbs: 5g, Fat: 1.5g",
      sku: "RSK002",
      productType: "Khari"
    },
    {
      name: "Milk Rusk",
      description: "Soft and sweet milk rusk for children and adults alike",
      inStock: false,
      price: 50,
      quantity: 0,
      weight: "280g",
      brand: "Milk Magic",
      ingredients: "Wheat flour, milk powder, sugar, butter",
      nutritionalInfo: "Calories: 45 per piece, Protein: 1.5g, Carbs: 9g, Fat: 1g",
      sku: "RSK003",
      productType: "Rusk"
    },
    {
      name: "Jeera Khari",
      description: "Crispy khari biscuits flavored with cumin seeds",
      inStock: true,
      price: 55,
      quantity: 30,
      weight: "200g",
      brand: "Spice Delights",
      ingredients: "Refined flour, cumin seeds, butter, salt",
      nutritionalInfo: "Calories: 30 per piece, Protein: 0.5g, Carbs: 4g, Fat: 1.5g",
      sku: "RSK004",
      productType: "Khari"
    }
  ],
  tea_time: [
    {
      name: "Assorted Tea Cookies",
      description: "Perfect mix of cookies for your evening tea",
      inStock: true,
      price: 160,
      quantity: 20,
      weight: "400g",
      brand: "Tea Companion",
      ingredients: "Mixed flour, butter, flavors, sugar",
      nutritionalInfo: "Calories: 60 per cookie, Protein: 1g, Carbs: 10g, Fat: 2g",
      sku: "TEA001",
      productType: "Tea Time Snacks"
    },
    {
      name: "Masala Khari Puff",
      description: "Spiced khari puff perfect with masala chai",
      inStock: true,
      price: 40,
      quantity: 50,
      weight: "200g",
      brand: "Chai Treats",
      ingredients: "Refined flour, mixed spices, butter",
      nutritionalInfo: "Calories: 25 per piece, Protein: 0.5g, Carbs: 3g, Fat: 1.5g",
      sku: "TEA002",
      productType: "Tea Time Snacks"
    },
    {
      name: "Coconut Cookies",
      description: "Delicious cookies with shredded coconut",
      inStock: true,
      price: 120,
      quantity: 25,
      weight: "250g",
      brand: "Coco Delights",
      ingredients: "Coconut, flour, sugar, butter",
      nutritionalInfo: "Calories: 70 per cookie, Protein: 1g, Carbs: 9g, Fat: 4g",
      sku: "TEA003",
      productType: "Tea Time Snacks"
    },
    {
      name: "Elaichi Rusk",
      description: "Cardamom flavored rusk for aromatic tea time",
      inStock: true,
      price: 55,
      quantity: 30,
      weight: "300g",
      brand: "Spice Magic",
      ingredients: "Wheat flour, cardamom, sugar, butter",
      nutritionalInfo: "Calories: 35 per piece, Protein: 1g, Carbs: 7g, Fat: 0.5g",
      sku: "TEA004",
      productType: "Tea Time Snacks"
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

async function populateBakeriesCategory() {
  const categoryGroup = 'bakeries_biscuits';
  
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
populateBakeriesCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
