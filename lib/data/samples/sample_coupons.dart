import 'package:flutter/material.dart';

// Define a class to represent coupon data for all coupon types
class SampleCoupon {
  final String id;
  final String code;
  final String type; // 'percentage', 'fixed', 'free_product', 'conditional', 'free_delivery'
  final double value; // Discount value or percentage
  final double? minPurchase; // Minimum purchase requirement
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int? usageLimit; // Maximum usage count
  final List<String>? applicableProductIds; // Products this coupon can be applied to
  final List<String>? applicableCategories; // Categories this coupon can be applied to
  final String title; // Short title for the coupon
  final String description; // Detailed description
  final String? imageAsset; // Path to image asset if coupon has an image
  final Color backgroundColor; // Background color for the coupon card
  
  // For free product coupons
  final String? freeProductId;
  final String? freeProductName;
  final String? freeProductImage;
  
  // For conditional coupons (buy X get Y)
  final Map<String, dynamic>? conditions;

  const SampleCoupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.minPurchase,
    this.isActive = true,
    this.usageLimit,
    this.applicableProductIds,
    this.applicableCategories,
    this.imageAsset,
    this.backgroundColor = Colors.blue,
    this.freeProductId,
    this.freeProductName,
    this.freeProductImage,
    this.conditions,
  });
}

// Sample coupon data
List<SampleCoupon> getSampleCoupons() {
  return [
    // Percentage discount coupons
    SampleCoupon(
      id: '1',
      code: 'WELCOME25',
      type: 'percentage',
      value: 25.0,
      title: '25% OFF on your first order',
      description: 'Get 25% off on your first order with a minimum purchase of ₹500',
      minPurchase: 500.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      backgroundColor: Colors.pink.shade800,
      imageAsset: 'assets/cimgs/1.jpg',
    ),
    SampleCoupon(
      id: '2',
      code: 'SUMMER20',
      type: 'percentage',
      value: 20.0,
      title: '20% OFF on all summer essentials',
      description: 'Beat the heat with 20% discount on all summer products',
      minPurchase: 300.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 60)),
      backgroundColor: Colors.orange.shade800,
      imageAsset: 'assets/cimgs/2.jpg',
      applicableCategories: ['summer', 'beverages', 'icecream'],
    ),
    
    // Fixed amount coupons
    SampleCoupon(
      id: '3',
      code: 'FLAT100',
      type: 'fixed',
      value: 100.0,
      title: '₹100 OFF on orders above ₹1000',
      description: 'Enjoy a flat ₹100 discount on your purchase of ₹1000 or more',
      minPurchase: 1000.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 15)),
      backgroundColor: Colors.purple.shade800,
      imageAsset: 'assets/cimgs/3.jpg',
    ),
    SampleCoupon(
      id: '4',
      code: 'SAVE50',
      type: 'fixed',
      value: 50.0,
      title: '₹50 OFF on household items',
      description: 'Get ₹50 off on all household items with minimum purchase of ₹500',
      minPurchase: 500.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 45)),
      backgroundColor: Colors.teal.shade800,
      applicableCategories: ['household', 'cleaning'],
    ),
    
    // Free delivery coupons
    SampleCoupon(
      id: '5',
      code: 'FREEDEL',
      type: 'free_delivery',
      value: 0.0,
      title: 'FREE Delivery on all orders',
      description: 'Enjoy free delivery with no minimum order value required',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      backgroundColor: Colors.green.shade800,
      imageAsset: 'assets/cimgs/4.jpg',
    ),
    
    // Free product coupons
    SampleCoupon(
      id: '6',
      code: 'FREEGIFT',
      type: 'free_product',
      value: 0.0,
      title: 'FREE Hand Sanitizer with every purchase',
      description: 'Get a free hand sanitizer (50ml) with any purchase above ₹300',
      minPurchase: 300.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      backgroundColor: Colors.amber.shade800,
      freeProductId: 'prod_sanitizer_01',
      freeProductName: 'Hand Sanitizer (50ml)',
      freeProductImage: 'assets/products/5.png',
    ),
    
    // Buy X Get Y coupons (Conditional)
    SampleCoupon(
      id: '7',
      code: 'BUY2GET1',
      type: 'conditional',
      value: 0.0,
      title: 'Buy 2 Get 1 Free on all beverages',
      description: 'Purchase any 2 beverages and get the third one free (lowest price will be free)',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 15)),
      backgroundColor: Colors.indigo.shade800,
      applicableCategories: ['beverages', 'drinks', 'juices'],
      conditions: {
        'buyQuantity': 2,
        'getQuantity': 1,
        'sameProduct': false,
        'sameCategory': true,
        'categoryId': 'beverages',
      },
      imageAsset: 'assets/cimgs/5.jpg',
    ),
    SampleCoupon(
      id: '8',
      code: 'COMBO50',
      type: 'conditional',
      value: 50.0,
      title: 'Save ₹50 when you buy Rice & Dal together',
      description: 'Add 1kg rice and 1kg dal to your cart and get ₹50 off instantly',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      backgroundColor: Colors.red.shade800,
      conditions: {
        'requiredProducts': ['prod_rice_01', 'prod_dal_01'],
        'requiredQuantities': [1, 1],
      },
    ),
    SampleCoupon(
      id: '9',
      code: 'FRESH20',
      type: 'conditional',
      value: 20.0,
      title: 'Get ₹20 off on Bread when buying Butter',
      description: 'Add any butter to your cart and get ₹20 off on your bread purchase',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 20)),
      backgroundColor: Colors.deepOrange.shade800,
      conditions: {
        'triggerProductId': 'prod_butter_category',
        'discountProductId': 'prod_bread_category',
        'triggerQuantity': 1,
      },
    ),
  ];
}
