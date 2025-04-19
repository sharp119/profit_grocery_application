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

// Product templates for different beauty categories
const productTemplates = {
  bath_body: [
    {
      name: "Luxe Body Wash",
      description: "Refreshing shower gel with natural extracts that cleanses and moisturizes",
      inStock: true,
      price: 299,
      quantity: 25,
      weight: "250ml",
      brand: "Wellness Co",
      ingredients: "Aqua, Aloe Vera, Glycerin, Essential Oils",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "BATH001",
      productType: "Bath & Body"
    },
    {
      name: "Exfoliating Body Scrub",
      description: "Coffee and walnut scrub for smooth, glowing skin",
      inStock: true,
      price: 349,
      quantity: 20,
      weight: "200g",
      brand: "Glow Essentials",
      ingredients: "Coffee grounds, Walnut shell powder, Olive oil",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "BATH002",
      productType: "Bath & Body"
    },
    {
      name: "Whipped Body Butter",
      description: "Luxurious shea butter cream for deep moisturization",
      inStock: true,
      price: 399,
      quantity: 15,
      weight: "300g",
      brand: "Silk Touch",
      ingredients: "Shea butter, Coconut oil, Vitamin E",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "BATH003",
      productType: "Bath & Body"
    },
    {
      name: "Bath Salts Set",
      description: "Relaxing Epsom salt blend with lavender and eucalyptus",
      inStock: true,
      price: 249,
      quantity: 30,
      weight: "500g",
      brand: "Spa Rituals",
      ingredients: "Epsom salt, Lavender oil, Eucalyptus oil",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "BATH004",
      productType: "Bath & Body"
    },
    {
      name: "Moroccan Argan Oil Body Lotion",
      description: "Nourishing body lotion enriched with pure argan oil",
      inStock: true,
      price: 279,
      quantity: 22,
      weight: "400ml",
      brand: "Natural Touch",
      ingredients: "Argan oil, Shea butter, Vitamin E, Glycerin",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "BATH005",
      productType: "Bath & Body"
    }
  ],
  feminine_hygiene: [
    {
      name: "Ultra Thin Sanitary Pads",
      description: "Super absorbent pads with wings for extra protection",
      inStock: true,
      price: 149,
      quantity: 60,
      weight: "18 pads",
      brand: "Care Plus",
      ingredients: "Cotton, Superabsorbent polymer",
      nutritionalInfo: "Not applicable for hygiene products",
      sku: "FEM001",
      productType: "Feminine Hygiene"
    },
    {
      name: "Organic Cotton Tampons",
      description: "Chemical-free, biodegradable tampons",
      inStock: true,
      price: 199,
      quantity: 45,
      weight: "16 pieces",
      brand: "Pure Hygiene",
      ingredients: "100% Organic cotton",
      nutritionalInfo: "Not applicable for hygiene products",
      sku: "FEM002",
      productType: "Feminine Hygiene"
    },
    {
      name: "Intimate Wash",
      description: "pH balanced gentle cleansing solution",
      inStock: true,
      price: 169,
      quantity: 35,
      weight: "150ml",
      brand: "Gentle Care",
      ingredients: "Lactic acid, Natural extracts, Glycerin",
      nutritionalInfo: "Not applicable for hygiene products",
      sku: "FEM003",
      productType: "Feminine Hygiene"
    },
    {
      name: "Menstrual Cup",
      description: "Reusable medical-grade silicone menstrual cup",
      inStock: true,
      price: 499,
      quantity: 20,
      weight: "1 cup - Large",
      brand: "Eco Period",
      ingredients: "Medical grade silicone",
      nutritionalInfo: "Not applicable for hygiene products",
      sku: "FEM004",
      productType: "Feminine Hygiene"
    }
  ],
  fragrances: [
    {
      name: "Floral Eau de Parfum",
      description: "Elegant fragrance with rose and jasmine notes",
      inStock: true,
      price: 1299,
      quantity: 15,
      weight: "50ml",
      brand: "Luxe Parfums",
      ingredients: "Alcohol denat., Fragrance, Water",
      nutritionalInfo: "Not applicable for fragrance products",
      sku: "FRAG001",
      productType: "Fragrances"
    },
    {
      name: "Citrus Fresh Cologne",
      description: "Refreshing citrus scent for everyday wear",
      inStock: true,
      price: 899,
      quantity: 25,
      weight: "100ml",
      brand: "Fresh Scents",
      ingredients: "Alcohol denat., Fragrance, Water",
      nutritionalInfo: "Not applicable for fragrance products",
      sku: "FRAG002",
      productType: "Fragrances"
    },
    {
      name: "Woody Perfume Spray",
      description: "Masculine woody fragrance with amber undertones",
      inStock: true,
      price: 1499,
      quantity: 12,
      weight: "75ml",
      brand: "Scent Master",
      ingredients: "Alcohol denat., Fragrance, Water",
      nutritionalInfo: "Not applicable for fragrance products",
      sku: "FRAG003",
      productType: "Fragrances"
    },
    {
      name: "Oriental Mist Body Spray",
      description: "Long-lasting body spray with oriental notes",
      inStock: true,
      price: 399,
      quantity: 40,
      weight: "150ml",
      brand: "Mist Essentials",
      ingredients: "Alcohol denat., Fragrance, Water",
      nutritionalInfo: "Not applicable for fragrance products",
      sku: "FRAG004",
      productType: "Fragrances"
    }
  ],
  hair_care: [
    {
      name: "Onion Hair Oil",
      description: "Hair growth oil infused with red onion extract",
      inStock: true,
      price: 299,
      quantity: 30,
      weight: "200ml",
      brand: "Hair Naturals",
      ingredients: "Onion extract, Coconut oil, Vitamin E",
      nutritionalInfo: "Not applicable for hair care products",
      sku: "HAIR001",
      productType: "Hair Care"
    },
    {
      name: "Anti-Dandruff Shampoo",
      description: "Therapeutic shampoo with tea tree oil and zinc pyrithione",
      inStock: true,
      price: 249,
      quantity: 40,
      weight: "400ml",
      brand: "Scalp Care",
      ingredients: "Tea tree oil, Zinc pyrithione, Natural cleansers",
      nutritionalInfo: "Not applicable for hair care products",
      sku: "HAIR002",
      productType: "Hair Care"
    },
    {
      name: "Hair Smoothening Serum",
      description: "Frizz control serum for silky smooth hair",
      inStock: true,
      price: 349,
      quantity: 25,
      weight: "100ml",
      brand: "Silk Strands",
      ingredients: "Argan oil, Silicones, Vitamin complex",
      nutritionalInfo: "Not applicable for hair care products",
      sku: "HAIR003",
      productType: "Hair Care"
    },
    {
      name: "Deep Conditioning Hair Mask",
      description: "Intensive repair mask for damaged hair",
      inStock: true,
      price: 429,
      quantity: 18,
      weight: "300g",
      brand: "Hair Repair",
      ingredients: "Keratin, Collagen, Natural oils",
      nutritionalInfo: "Not applicable for hair care products",
      sku: "HAIR004",
      productType: "Hair Care"
    },
    {
      name: "Volumizing Hair Spray",
      description: "Lightweight spray for volume and hold",
      inStock: true,
      price: 279,
      quantity: 22,
      weight: "150ml",
      brand: "Style Pro",
      ingredients: "Alcohol denat., Polymers, Panthenol",
      nutritionalInfo: "Not applicable for hair care products",
      sku: "HAIR005",
      productType: "Hair Care"
    }
  ],
  makeup: [
    {
      name: "Matte Liquid Lipstick Set",
      description: "Long-lasting liquid lipstick in 6 trendy shades",
      inStock: true,
      price: 699,
      quantity: 15,
      weight: "6 x 5ml",
      brand: "Color Crush",
      ingredients: "Synthetic wax, Polymers, Pigments",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "MAKE001",
      productType: "Makeup"
    },
    {
      name: "HD Foundation",
      description: "Lightweight foundation with medium coverage",
      inStock: true,
      price: 899,
      quantity: 25,
      weight: "30ml",
      brand: "Flawless Finish",
      ingredients: "Water, Silicone polymers, Pigments",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "MAKE002",
      productType: "Makeup"
    },
    {
      name: "Waterproof Mascara",
      description: "Volume and length mascara with smudge-proof formula",
      inStock: true,
      price: 449,
      quantity: 35,
      weight: "10ml",
      brand: "Lash Luxe",
      ingredients: "Wax, Polymers, Pigments",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "MAKE003",
      productType: "Makeup"
    },
    {
      name: "Eyeshadow Palette",
      description: "12-shade palette with matte and shimmer finishes",
      inStock: true,
      price: 999,
      quantity: 18,
      weight: "12g",
      brand: "Eye Artistry",
      ingredients: "Mica, Talc, Pigments",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "MAKE004",
      productType: "Makeup"
    },
    {
      name: "Blush and Highlighter Duo",
      description: "Compact with complementary blush and highlighter",
      inStock: true,
      price: 599,
      quantity: 20,
      weight: "8g",
      brand: "Glow Up",
      ingredients: "Mica, Talc, Synthetic fluorphlogopite",
      nutritionalInfo: "Not applicable for cosmetic products",
      sku: "MAKE005",
      productType: "Makeup"
    }
  ],
  men_grooming: [
    {
      name: "Beard Oil",
      description: "Nourishing beard oil with cedarwood and sandalwood",
      inStock: true,
      price: 399,
      quantity: 30,
      weight: "50ml",
      brand: "Beard Master",
      ingredients: "Argan oil, Jojoba oil, Essential oils",
      nutritionalInfo: "Not applicable for grooming products",
      sku: "MEN001",
      productType: "Men's Grooming"
    },
    {
      name: "Face Wash for Men",
      description: "Energizing face wash with activated charcoal",
      inStock: true,
      price: 179,
      quantity: 40,
      weight: "150ml",
      brand: "Man Basics",
      ingredients: "Charcoal, Tea tree oil, Glycerin",
      nutritionalInfo: "Not applicable for grooming products",
      sku: "MEN002",
      productType: "Men's Grooming"
    },
    {
      name: "Hair Styling Clay",
      description: "Matte finish styling clay for textured looks",
      inStock: true,
      price: 349,
      quantity: 25,
      weight: "100g",
      brand: "Style Men",
      ingredients: "Bentonite clay, Beeswax, Essential oils",
      nutritionalInfo: "Not applicable for grooming products",
      sku: "MEN003",
      productType: "Men's Grooming"
    },
    {
      name: "After Shave Balm",
      description: "Soothing balm with aloe vera and vitamin E",
      inStock: true,
      price: 249,
      quantity: 35,
      weight: "100ml",
      brand: "Shave Pro",
      ingredients: "Aloe vera, Vitamin E, Witch hazel",
      nutritionalInfo: "Not applicable for grooming products",
      sku: "MEN004",
      productType: "Men's Grooming"
    }
  ],
  personal_care: [
    {
      name: "Moisturizing Hand Cream",
      description: "Intensive care for dry and rough hands",
      inStock: true,
      price: 129,
      quantity: 50,
      weight: "75ml",
      brand: "Hand Care Plus",
      ingredients: "Glycerin, Shea butter, Vitamin E",
      nutritionalInfo: "Not applicable for personal care products",
      sku: "PERS001",
      productType: "Personal Care"
    },
    {
      name: "Natural Deodorant Stick",
      description: "Aluminum-free deodorant with 24-hour protection",
      inStock: true,
      price: 199,
      quantity: 40,
      weight: "50g",
      brand: "Fresh All Day",
      ingredients: "Coconut oil, Baking soda, Essential oils",
      nutritionalInfo: "Not applicable for personal care products",
      sku: "PERS002",
      productType: "Personal Care"
    },
    {
      name: "Lip Balm SPF 15",
      description: "Moisturizing lip balm with sun protection",
      inStock: true,
      price: 99,
      quantity: 100,
      weight: "4g",
      brand: "Lip Care",
      ingredients: "Beeswax, Shea butter, SPF 15",
      nutritionalInfo: "Not applicable for personal care products",
      sku: "PERS003",
      productType: "Personal Care"
    },
    {
      name: "Foot Cream",
      description: "Healing foot cream for cracked heels",
      inStock: true,
      price: 169,
      quantity: 30,
      weight: "100ml",
      brand: "Foot Relief",
      ingredients: "Urea, Peppermint oil, Aloe vera",
      nutritionalInfo: "Not applicable for personal care products",
      sku: "PERS004",
      productType: "Personal Care"
    },
    {
      name: "Talcum Powder",
      description: "Classic fresh-scented talcum powder",
      inStock: true,
      price: 89,
      quantity: 60,
      weight: "200g",
      brand: "Fresh & Soft",
      ingredients: "Talc, Fragrance, Magnesium carbonate",
      nutritionalInfo: "Not applicable for personal care products",
      sku: "PERS005",
      productType: "Personal Care"
    }
  ],
  skin_care: [
    {
      name: "Vitamin C Serum",
      description: "Anti-aging serum with pure vitamin C for radiant skin",
      inStock: true,
      price: 899,
      quantity: 20,
      weight: "30ml",
      brand: "Glow Science",
      ingredients: "L-ascorbic acid, Hyaluronic acid, Vitamin E",
      nutritionalInfo: "Not applicable for skincare products",
      sku: "SKIN001",
      productType: "Skin Care"
    },
    {
      name: "Retinol Night Cream",
      description: "Anti-wrinkle cream with retinol for overnight repair",
      inStock: true,
      price: 999,
      quantity: 15,
      weight: "50g",
      brand: "Age Defy",
      ingredients: "Retinol, Peptides, Hyaluronic acid",
      nutritionalInfo: "Not applicable for skincare products",
      sku: "SKIN002",
      productType: "Skin Care"
    },
    {
      name: "Clay Face Mask",
      description: "Purifying face mask with bentonite clay",
      inStock: true,
      price: 349,
      quantity: 25,
      weight: "100g",
      brand: "Clear Skin",
      ingredients: "Bentonite clay, Kaolin clay, Witch hazel",
      nutritionalInfo: "Not applicable for skincare products",
      sku: "SKIN003",
      productType: "Skin Care"
    },
    {
      name: "SPF 50 Sunscreen",
      description: "Broad-spectrum sunscreen with PA+++",
      inStock: true,
      price: 549,
      quantity: 40,
      weight: "50ml",
      brand: "Sun Guard",
      ingredients: "Zinc oxide, Titanium dioxide, Aloe vera",
      nutritionalInfo: "Not applicable for skincare products",
      sku: "SKIN004",
      productType: "Skin Care"
    },
    {
      name: "Hyaluronic Acid Moisturizer",
      description: "Intensive hydrating cream for all skin types",
      inStock: true,
      price: 799,
      quantity: 22,
      weight: "50g",
      brand: "Hydra Plus",
      ingredients: "Hyaluronic acid, Ceramides, Glycerin",
      nutritionalInfo: "Not applicable for skincare products",
      sku: "SKIN005",
      productType: "Skin Care"
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

async function populateBeautyCategory() {
  const categoryGroup = 'beauty_personal_care';
  
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
populateBeautyCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
