import { initializeApp } from 'firebase/app';
    import { getFirestore, collection, getDocs } from 'firebase/firestore';
    import fs from 'fs';
    import path from 'path';
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
    
    async function downloadCoupons() {
      console.log('🚀 Starting to download all coupons from Firestore...');
      console.log('='.repeat(60));
      
      const startTime = Date.now();
      let totalCouponsDownloaded = 0;
      
      try {
        const couponsRef = collection(db, 'coupons'); // Target the 'coupons' collection
        const couponsSnapshot = await getDocs(couponsRef);
        
        const allCoupons = [];
        
        couponsSnapshot.forEach((couponDoc) => {
          const couponData = couponDoc.data();
          
          const coupon = {
            id: couponDoc.id,
            ...couponData,
            // Convert Firestore timestamps to ISO strings if they exist
            createdAt: couponData.createdAt?.toDate?.()?.toISOString() || couponData.createdAt,
            updatedAt: couponData.updatedAt?.toDate?.()?.toISOString() || couponData.updatedAt,
            startTimestamp: couponData.startTimestamp?.toDate?.()?.toISOString() || couponData.startTimestamp,
            endTimestamp: couponData.endTimestamp?.toDate?.()?.toISOString() || couponData.endTimestamp
          };
          
          allCoupons.push(coupon);
          totalCouponsDownloaded++;
        });
        
        const exportData = {
          metadata: {
            exportDate: new Date().toISOString(),
            totalCoupons: totalCouponsDownloaded,
            exportDurationMs: Date.now() - startTime,
            firebaseProject: process.env.FIREBASE_PROJECT_ID
          },
          coupons: allCoupons
        };
        
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filename = `firestore_coupons_export_${timestamp}.json`;
        const filepath = path.join(process.cwd(), filename);
        
        fs.writeFileSync(filepath, JSON.stringify(exportData, null, 2), 'utf8');
        
        console.log('\\n' + '='.repeat(60));
        console.log('🎉 COUPONS EXPORT COMPLETED SUCCESSFULLY!');
        console.log('='.repeat(60));
        console.log(`📊 Total Coupons Downloaded: ${totalCouponsDownloaded}`);
        console.log(`⏱️  Export Duration: ${(Date.now() - startTime) / 1000} seconds`);
        console.log(`💾 JSON Export saved to: ${filename}`);
        console.log('='.repeat(60));
        
        return exportData;
        
      } catch (error) {
        console.error('\\n❌ COUPONS EXPORT FAILED:');
        console.error('Error:', error.message);
        console.error('Stack:', error.stack);
        throw error;
      }
    }
    
    // Run the export
    downloadCoupons()
      .then(() => {
        console.log('\\n✅ Script completed successfully');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\\n💥 Script failed with error:', error.message);
        process.exit(1);
      });