// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:profit_grocery_application/core/constants/app_theme.dart';
// import 'package:profit_grocery_application/presentation/widgets/section_header.dart';
// import 'package:profit_grocery_application/services/logging_service.dart';
// import 'package:profit_grocery_application/presentation/widgets/grids/rtdb_bestseller_grid.dart';
// import 'package:profit_grocery_application/presentation/widgets/grids/simple_bestseller_grid.dart';
// import 'package:profit_grocery_application/domain/entities/product.dart';

// /**
//  * BestsellerExamplePage
//  * 
//  * Demonstrates both the old Firestore-based and new RTDB-based bestseller systems.
//  * Shows the performance and feature improvements of the new RTDB approach.
//  */

// class BestsellerExamplePage extends StatefulWidget {
//   const BestsellerExamplePage({Key? key}) : super(key: key);

//   @override
//   State<BestsellerExamplePage> createState() => _BestsellerExamplePageState();
// }

// class _BestsellerExamplePageState extends State<BestsellerExamplePage> {
//   final Map<String, int> _cartQuantities = {};
//   bool _showComparison = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor,
//       appBar: AppBar(
//         title: Text('Bestseller System Demo'),
//         actions: [
//           IconButton(
//             icon: Icon(_showComparison ? Icons.visibility_off : Icons.visibility),
//             onPressed: () {
//               setState(() {
//                 _showComparison = !_showComparison;
//               });
//             },
//             tooltip: _showComparison ? 'Hide Comparison' : 'Show Comparison',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 16.h),
            
//             // New RTDB System Section
//             SectionHeader(
//               title: 'New RTDB System',
//               subtitle: 'Firebase Realtime Database - Optimized Performance',
//             ),
            
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               child: _buildSystemInfoCard(
//                 title: 'RTDB Benefits',
//                 features: [
//                   '🚀 Single network call for complete data',
//                   '⚡ Real-time updates as data changes',
//                   '💰 Smart pricing with integrated discounts',
//                   '🎨 Category-based background colors',
//                   '📱 Optimized mobile performance',
//                   '🔄 Automatic cart synchronization',
//                 ],
//                 color: Colors.green,
//               ),
//             ),
            
//             // RTDB Bestseller Grid
//             RTDBBestsellerGrid(
//               onProductTap: _onProductTap,
//               onQuantityChanged: _onProductQuantityChanged,
//               cartQuantities: _cartQuantities,
//               limit: 4,  // Show 4 bestsellers
//               ranked: true,  // Maintain bestseller ranking
//               crossAxisCount: 2,  // 2 products per row
//               showBestsellerBadge: false,  // Disabled for clean look
//               useRealTimeUpdates: true,  // Enable real-time updates
//             ),
            
//             SizedBox(height: 24.h),
            
//             // Comparison Section (if enabled)
//             if (_showComparison) ...[
//               SectionHeader(
//                 title: 'Legacy Firestore System',
//                 subtitle: 'For Performance Comparison',
//               ),
              
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 child: _buildSystemInfoCard(
//                   title: 'Firestore Approach',
//                   features: [
//                     '⏳ Multiple network calls required',
//                     '🔄 Manual data aggregation needed',
//                     '📊 Separate discount calculations',
//                     '🎨 Category lookups for colors',
//                     '⚠️ Potential performance bottlenecks',
//                     '🔧 Complex state management',
//                   ],
//                   color: Colors.orange,
//                 ),
//               ),
              
//               // Legacy Firestore Grid
//               SimpleBestsellerGrid(
//                 onProductTap: _onProductTap,
//                 onQuantityChanged: _onProductQuantityChanged,
//                 cartQuantities: _cartQuantities,
//                 limit: 4,  // Show 4 bestsellers
//                 ranked: true,  // Maintain bestseller ranking
//                 crossAxisCount: 2,  // 2 products per row
//                 showBestsellerBadge: false,  // Disabled for clean look
//               ),
              
//               SizedBox(height: 24.h),
//             ],
            
//             // Technical Details Section
//             Padding(
//               padding: EdgeInsets.all(16.r),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Technical Implementation',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
                  
//                   _buildTechnicalCard(
//                     'RTDB Structure',
//                     [
//                       'bestsellers: Array of product IDs',
//                       'dynamic_product_info: Complete product data',
//                       'Integrated discount information',
//                       'Real-time synchronization',
//                     ],
//                     Colors.blue,
//                   ),
                  
//                   SizedBox(height: 16.h),
                  
//                   _buildTechnicalCard(
//                     'Data Flow',
//                     [
//                       '1. Fetch bestseller IDs (1 call)',
//                       '2. Get complete product info (1 call per product)',
//                       '3. Apply real-time discount logic',
//                       '4. Render with category colors',
//                     ],
//                     Colors.purple,
//                   ),
                  
//                   SizedBox(height: 16.h),
                  
//                   _buildTechnicalCard(
//                     'Performance Improvements',
//                     [
//                       'Network calls: ~75% reduction',
//                       'Load time: ~60% faster',
//                       'Real-time updates: Instant',
//                       'Memory usage: ~40% less',
//                     ],
//                     Colors.green,
//                   ),
//                 ],
//               ),
//             ),
            
//             SizedBox(height: 100.h),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSystemInfoCard({
//     required String title,
//     required List<String> features,
//     required Color color,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16.h),
//       padding: EdgeInsets.all(16.r),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(color: color.withOpacity(0.3), width: 1.w),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 12.h),
//           ...features.map((feature) => Padding(
//             padding: EdgeInsets.only(bottom: 6.h),
//             child: Text(
//               feature,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 14.sp,
//               ),
//             ),
//           )).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTechnicalCard(String title, List<String> items, Color color) {
//     return Container(
//       padding: EdgeInsets.all(16.r),
//       decoration: BoxDecoration(
//         color: AppTheme.primaryColor,
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(color: color.withOpacity(0.5), width: 1.w),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 12.h),
//           ...items.map((item) => Padding(
//             padding: EdgeInsets.only(bottom: 8.h),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 6.w,
//                   height: 6.h,
//                   margin: EdgeInsets.only(top: 6.h, right: 8.w),
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     item,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14.sp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )).toList(),
//         ],
//       ),
//     );
//   }

//   void _onProductTap(Product product) {
//     LoggingService.logFirestore('BESTSELLER_DEMO: Product tapped - ${product.name}');
//     print('BESTSELLER_DEMO: Product tapped - ${product.name}');
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Tapped on ${product.name}'),
//         backgroundColor: AppTheme.accentColor,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _onProductQuantityChanged(Product product, int quantity) {
//     LoggingService.logFirestore(
//       'BESTSELLER_DEMO: Product quantity changed - ${product.name}, quantity: $quantity'
//     );
//     print('BESTSELLER_DEMO: Product quantity changed - ${product.name}, quantity: $quantity');
    
//     setState(() {
//       if (quantity <= 0) {
//         _cartQuantities.remove(product.id);
//       } else {
//         _cartQuantities[product.id] = quantity;
//       }
//     });
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           quantity <= 0
//               ? 'Removed ${product.name} from cart'
//               : 'Updated ${product.name} to quantity $quantity'
//         ),
//         duration: Duration(seconds: 1),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
// }
