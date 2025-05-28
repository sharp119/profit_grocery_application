import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

// Represents a single item within an order
class OrderItem {
  final String productId;
  final String name; // Denormalized for easy display
  final String image; // Denormalized for easy display
  final double mrp; // MRP at the time of order
  final double buyingPrice; // Actual price paid for this item (after item-specific discounts)
  final int quantity;
  // Optional: add variant details if your products have them (e.g., size, color)
  // final String? variantId;
  // final String? variantName;

  OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.mrp,
    required this.buyingPrice,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'image': image,
        'mrp': mrp,
        'buyingPrice': buyingPrice,
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      mrp: (json['mrp'] as num).toDouble(),
      buyingPrice: (json['buyingPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

// Shipping Address for the order (structure as defined in CartPage)
class ShippingAddressOrder {
  final String name;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? phone;
  final String? landmark;
  final String? addressType;

  ShippingAddressOrder({
    required this.name,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.phone,
    this.landmark,
    this.addressType,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'phone': phone,
        'landmark': landmark,
        'addressType': addressType,
      };

  factory ShippingAddressOrder.fromJson(Map<String, dynamic> json) {
    return ShippingAddressOrder(
      name: json['name'] as String,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      phone: json['phone'] as String?,
      landmark: json['landmark'] as String?,
      addressType: json['addressType'] as String?,
    );
  }
}

// Payment Details for the order
class PaymentDetailsOrder {
  final String paymentId; // From payment gateway
  final String method; // e.g., "razorpay", "upi", "card"
  final double amountPaid; // Should match pricingSummary.grandTotal
  final String currency; // e.g., "INR"
  final Timestamp? initiationTime; // When payment process was started by user
  final Timestamp successTime;    // When payment was confirmed successful (can be order creation time)
  // Optional: gatewayTransactionId, orderIdFromGateway if different from paymentId

  PaymentDetailsOrder({
    required this.paymentId,
    required this.method,
    required this.amountPaid,
    required this.currency,
    this.initiationTime,
    required this.successTime,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'method': method,
        'amountPaid': amountPaid,
        'currency': currency,
        'initiationTime': initiationTime,
        'successTime': successTime,
      };

  factory PaymentDetailsOrder.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsOrder(
      paymentId: json['paymentId'] as String,
      method: json['method'] as String,
      amountPaid: (json['amountPaid'] as num).toDouble(),
      currency: json['currency'] as String,
      initiationTime: json['initiationTime'] as Timestamp?,
      successTime: json['successTime'] as Timestamp,
    );
  }
}

// Pricing Summary for the order
class PricingSummaryOrder {
  final double subtotal; // Sum of (mrp * quantity) for all items
  final double itemDiscountsTotal; // Sum of (mrp - buyingPrice) * quantity for all items
  final String? couponCodeApplied;
  final double couponDiscountAmount; // Discount specifically from the coupon
  final double deliveryFee;
  final double packagingFee; // If you have this
  final double grandTotal; // Final amount paid by user

  PricingSummaryOrder({
    required this.subtotal,
    required this.itemDiscountsTotal,
    this.couponCodeApplied,
    required this.couponDiscountAmount,
    required this.deliveryFee,
    this.packagingFee = 0.0, // Default if not applicable
    required this.grandTotal,
  });

  Map<String, dynamic> toJson() => {
        'subtotal': subtotal,
        'itemDiscountsTotal': itemDiscountsTotal,
        'couponCodeApplied': couponCodeApplied,
        'couponDiscountAmount': couponDiscountAmount,
        'deliveryFee': deliveryFee,
        'packagingFee': packagingFee,
        'grandTotal': grandTotal,
      };

  factory PricingSummaryOrder.fromJson(Map<String, dynamic> json) {
    return PricingSummaryOrder(
      subtotal: (json['subtotal'] as num).toDouble(),
      itemDiscountsTotal: (json['itemDiscountsTotal'] as num).toDouble(),
      couponCodeApplied: json['couponCodeApplied'] as String?,
      couponDiscountAmount: (json['couponDiscountAmount'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      packagingFee: (json['packagingFee'] as num? ?? 0.0).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
    );
  }
}

// The main Order Entity
class OrderEntity {
  final String? id; // Firestore document ID (orderId), null when creating
  final String userId; // Still useful to have, even if path contains it
  final Timestamp orderTimestamp; // Renamed from orderDate for clarity with your request
  final String status; // e.g., "pending", "processing", "shipped", "delivered", "cancelled", "refunded"
  final List<OrderItem> items;
  final ShippingAddressOrder shippingAddress;
  final PaymentDetailsOrder paymentDetails;
  final PricingSummaryOrder pricingSummary;
  // Optional:
  // final String? orderNotes;
  // final Timestamp? lastUpdated;

  OrderEntity({
    this.id,
    required this.userId,
    required this.orderTimestamp,
    required this.status,
    required this.items,
    required this.shippingAddress,
    required this.paymentDetails,
    required this.pricingSummary,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId, // Good to keep for data portability/denormalization
        'orderTimestamp': orderTimestamp,
        'status': status,
        'items': items.map((item) => item.toJson()).toList(),
        'shippingAddress': shippingAddress.toJson(),
        'paymentDetails': paymentDetails.toJson(),
        'pricingSummary': pricingSummary.toJson(),
        // 'lastUpdated': FieldValue.serverTimestamp(), // For updates
      };

  factory OrderEntity.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return OrderEntity(
      id: snap.id,
      userId: data['userId'] as String,
      orderTimestamp: data['orderTimestamp'] as Timestamp,
      status: data['status'] as String,
      items: (data['items'] as List<dynamic>)
          .map((itemData) => OrderItem.fromJson(itemData as Map<String, dynamic>))
          .toList(),
      shippingAddress: ShippingAddressOrder.fromJson(data['shippingAddress'] as Map<String, dynamic>),
      paymentDetails: PaymentDetailsOrder.fromJson(data['paymentDetails'] as Map<String, dynamic>),
      pricingSummary: PricingSummaryOrder.fromJson(data['pricingSummary'] as Map<String, dynamic>),
    );
  }
}