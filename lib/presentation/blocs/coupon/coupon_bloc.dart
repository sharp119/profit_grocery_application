import 'package:flutter_bloc/flutter_bloc.dart';

import 'coupon_event.dart';
import 'coupon_state.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  // In a real app, we would inject repository dependencies here
  // final CouponRepository _couponRepository;

  CouponBloc() : super(const CouponState()) {
    on<LoadCoupons>(_onLoadCoupons);
    on<ValidateCoupon>(_onValidateCoupon);
    on<ValidateDeepLinkCoupon>(_onValidateDeepLinkCoupon);
    on<ClearDeepLinkCoupon>(_onClearDeepLinkCoupon);
  }

  Future<void> _onLoadCoupons(
    LoadCoupons event,
    Emitter<CouponState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CouponStatus.loading));

      // In a real app, we would fetch coupons from a repository
      // For now, we'll use mock data
      final coupons = _getMockCoupons();
      
      // Check if deep link coupon is provided
      if (event.deepLinkCoupon != null && event.deepLinkCoupon!.isNotEmpty) {
        // Validate deep link coupon
        add(ValidateDeepLinkCoupon(event.deepLinkCoupon!));
      } else {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Return all available coupons
        emit(state.copyWith(
          status: CouponStatus.loaded,
          coupons: coupons,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CouponStatus.error,
        errorMessage: 'Failed to load coupons: $e',
      ));
    }
  }

  Future<void> _onValidateCoupon(
    ValidateCoupon event,
    Emitter<CouponState> emit,
  ) async {
    try {
      // In a real app, we would validate the coupon with a repository
      // For now, we'll just check if the coupon exists in our mock data
      final code = event.code.toUpperCase();
      final mockCoupons = _getMockCoupons();
      final isValid = mockCoupons.any((coupon) => coupon.code == code);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (isValid) {
        emit(state.copyWith(
          status: CouponStatus.loaded,
        ));
      } else {
        emit(state.copyWith(
          status: CouponStatus.error,
          errorMessage: 'Invalid coupon code',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CouponStatus.error,
        errorMessage: 'Failed to validate coupon: $e',
      ));
    }
  }

  Future<void> _onValidateDeepLinkCoupon(
    ValidateDeepLinkCoupon event,
    Emitter<CouponState> emit,
  ) async {
    try {
      // In a real app, we would validate the deep link coupon with a repository
      // For now, we'll use mock data for a valid deep link coupon
      final code = event.code.toUpperCase();
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Get available coupons
      final coupons = _getMockCoupons();
      
      // Check if deep link coupon is one of our mock coupons
      final couponInfo = coupons.firstWhere(
        (coupon) => coupon.code == code,
        orElse: () => CouponInfo(
          code: code,
          discount: 'Special Discount',
          description: 'Special offer just for you!',
          minOrderValue: '₹500',
          expiryDate: '2025-06-01',
        ),
      );
      
      // Create deep link coupon info
      final deepLinkCouponInfo = DeepLinkCouponInfo(
        discount: couponInfo.discount,
        minOrderValue: couponInfo.minOrderValue,
        expiryDate: couponInfo.expiryDate,
        description: couponInfo.description,
      );
      
      emit(state.copyWith(
        status: CouponStatus.deepLinkCouponValid,
        deepLinkCoupon: code,
        deepLinkCouponInfo: deepLinkCouponInfo,
        coupons: coupons,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CouponStatus.deepLinkCouponInvalid,
        errorMessage: 'Invalid deep link coupon: $e',
      ));
    }
  }

  void _onClearDeepLinkCoupon(
    ClearDeepLinkCoupon event,
    Emitter<CouponState> emit,
  ) {
    emit(state.copyWith(
      deepLinkCoupon: null,
      deepLinkCouponInfo: null,
    ));
  }
  
  // Mock data methods
  List<CouponInfo> _getMockCoupons() {
    return [
      CouponInfo(
        code: 'WELCOME10',
        discount: '10% off on your first order',
        minOrderValue: '₹200',
        expiryDate: '2025-05-31',
        description: 'Get 10% off on your first order with a minimum order value of ₹200.',
      ),
      CouponInfo(
        code: 'SAVE15',
        discount: '15% off on orders above ₹500',
        minOrderValue: '₹500',
        expiryDate: '2025-06-15',
        description: 'Get 15% off on your order with a minimum order value of ₹500.',
      ),
      CouponInfo(
        code: 'FIRST20',
        discount: '20% off on selected items',
        expiryDate: '2025-06-30',
        description: 'Get 20% off on selected grocery items. Limited time offer!',
      ),
      CouponInfo(
        code: 'FREESHIP',
        discount: 'Free shipping on all orders',
        minOrderValue: '₹300',
        expiryDate: '2025-07-15',
        description: 'Get free shipping on all orders with a minimum order value of ₹300.',
      ),
      CouponInfo(
        code: 'SUMMER25',
        discount: '25% off on summer essentials',
        minOrderValue: '₹1000',
        expiryDate: '2025-08-31',
        description: 'Get 25% off on all summer essentials with a minimum order value of ₹1000.',
      ),
    ];
  }
}