/// Types of coupons supported by the application
enum CouponType {
  /// Percentage discount (e.g., 10% off)
  percentage,
  
  /// Fixed amount discount (e.g., ₹100 off)
  fixedAmount,
  
  /// Free delivery coupon
  freeDelivery,
  
  /// Buy one get one free
  buyOneGetOne,
  
  /// Free product coupon
  freeProduct,
  
  /// Conditional discount (e.g., buy X get Y free)
  conditional
}
