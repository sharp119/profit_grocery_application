import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  // In a real app, we would inject repository dependencies here
  // final CartRepository _cartRepository;
  // final UserRepository _userRepository;
  // final OrderRepository _orderRepository;

  CheckoutBloc() : super(const CheckoutState()) {
    on<LoadCheckout>(_onLoadCheckout);
    on<SelectAddress>(_onSelectAddress);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<ApplyCoupon>(_onApplyCoupon);
    on<RemoveCoupon>(_onRemoveCoupon);
    on<PlaceOrder>(_onPlaceOrder);
    on<AddAddress>(_onAddAddress);
    on<UpdateAddress>(_onUpdateAddress);
    on<DeleteAddress>(_onDeleteAddress);
  }

  Future<void> _onLoadCheckout(
    LoadCheckout event,
    Emitter<CheckoutState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CheckoutStatus.loading));

      // In a real app, we would fetch data from repositories
      // For now, we'll use mock data
      final addresses = _getMockAddresses();
      final selectedAddress = addresses.firstWhere((address) => address.isDefault);
      final paymentMethods = _getMockPaymentMethods();
      
      // Mock cart data
      final subtotal = 798.0;
      final discount = 79.8; // 10% discount
      final deliveryFee = selectedAddress.pincode == '110001' ? 0.0 : 40.0; // Free delivery for 110001
      final total = subtotal - discount + deliveryFee;
      final itemCount = 4;
      final couponCode = 'WELCOME10';
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      emit(state.copyWith(
        status: CheckoutStatus.loaded,
        addresses: addresses,
        selectedAddress: selectedAddress,
        paymentMethods: paymentMethods,
        selectedPaymentMethodId: 0, // Default to first payment method
        subtotal: subtotal,
        discount: discount,
        deliveryFee: deliveryFee,
        total: total,
        itemCount: itemCount,
        couponCode: couponCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to load checkout data: $e',
      ));
    }
  }

  void _onSelectAddress(
    SelectAddress event,
    Emitter<CheckoutState> emit,
  ) {
    try {
      final selectedAddressId = event.addressId;
      final selectedAddress = state.addresses.firstWhere(
        (address) => address.id == selectedAddressId,
      );
      
      // Recalculate delivery fee based on selected address
      final deliveryFee = selectedAddress.pincode == '110001' ? 0.0 : 40.0;
      final total = state.subtotal - state.discount + deliveryFee;
      
      emit(state.copyWith(
        selectedAddress: selectedAddress,
        deliveryFee: deliveryFee,
        total: total,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to select address: $e',
      ));
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<CheckoutState> emit,
  ) {
    final paymentMethodId = event.paymentMethodId;
    emit(state.copyWith(selectedPaymentMethodId: paymentMethodId));
  }

  Future<void> _onApplyCoupon(
    ApplyCoupon event,
    Emitter<CheckoutState> emit,
  ) async {
    try {
      // In a real app, we would validate the coupon with a repository
      // For now, we'll just apply a fixed discount
      final code = event.code;
      
      // Apply mock discount based on coupon code
      double discount = 0.0;
      if (code == 'WELCOME10') {
        discount = state.subtotal * 0.1; // 10% discount
      } else if (code == 'SAVE15') {
        discount = state.subtotal * 0.15; // 15% discount
      } else if (code == 'FIRST20') {
        discount = state.subtotal * 0.2; // 20% discount
      } else {
        // Default discount
        discount = state.subtotal * 0.05; // 5% discount
      }
      
      // Recalculate total
      final total = state.subtotal - discount + state.deliveryFee;
      
      emit(state.copyWith(
        couponCode: code,
        discount: discount,
        total: total,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to apply coupon: $e',
      ));
    }
  }

  void _onRemoveCoupon(
    RemoveCoupon event,
    Emitter<CheckoutState> emit,
  ) {
    try {
      // Recalculate total without discount
      final total = state.subtotal + state.deliveryFee;
      
      emit(state.copyWith(
        couponCode: null,
        discount: 0.0,
        total: total,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to remove coupon: $e',
      ));
    }
  }

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<CheckoutState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CheckoutStatus.placingOrder));
      
      // In a real app, we would place the order with a repository
      // For now, we'll just simulate a network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate a mock order ID
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      emit(state.copyWith(
        status: CheckoutStatus.orderSuccess,
        orderId: orderId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to place order: $e',
      ));
    }
  }

  void _onAddAddress(
    AddAddress event,
    Emitter<CheckoutState> emit,
  ) {
    try {
      final newAddress = event.address;
      final updatedAddresses = List<UserAddress>.from(state.addresses)..add(newAddress);
      
      // If this is the first address, make it the default and selected address
      UserAddress selectedAddress = state.selectedAddress ?? newAddress;
      if (newAddress.isDefault) {
        // Update all other addresses to not be default
        for (int i = 0; i < updatedAddresses.length - 1; i++) {
          final address = updatedAddresses[i];
          if (address.isDefault) {
            updatedAddresses[i] = UserAddress(
              id: address.id,
              name: address.name,
              phone: address.phone,
              address: address.address,
              pincode: address.pincode,
              type: address.type,
              isDefault: false,
            );
          }
        }
        selectedAddress = newAddress;
      }
      
      // Recalculate delivery fee based on selected address
      final deliveryFee = selectedAddress.pincode == '110001' ? 0.0 : 40.0;
      final total = state.subtotal - state.discount + deliveryFee;
      
      emit(state.copyWith(
        addresses: updatedAddresses,
        selectedAddress: selectedAddress,
        deliveryFee: deliveryFee,
        total: total,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to add address: $e',
      ));
    }
  }

  void _onUpdateAddress(
    UpdateAddress event,
    Emitter<CheckoutState> emit,
  ) {
    try {
      final updatedAddress = event.address;
      final updatedAddresses = List<UserAddress>.from(state.addresses);
      
      // Find the index of the address to update
      final index = updatedAddresses.indexWhere(
        (address) => address.id == updatedAddress.id,
      );
      
      if (index != -1) {
        updatedAddresses[index] = updatedAddress;
        
        // If updated address is set as default, update all other addresses
        if (updatedAddress.isDefault) {
          for (int i = 0; i < updatedAddresses.length; i++) {
            if (i != index && updatedAddresses[i].isDefault) {
              updatedAddresses[i] = UserAddress(
                id: updatedAddresses[i].id,
                name: updatedAddresses[i].name,
                phone: updatedAddresses[i].phone,
                address: updatedAddresses[i].address,
                pincode: updatedAddresses[i].pincode,
                type: updatedAddresses[i].type,
                isDefault: false,
              );
            }
          }
        }
        
        // Update selected address if needed
        UserAddress? selectedAddress = state.selectedAddress;
        if (state.selectedAddress?.id == updatedAddress.id) {
          selectedAddress = updatedAddress;
          
          // Recalculate delivery fee based on selected address
          final deliveryFee = selectedAddress.pincode == '110001' ? 0.0 : 40.0;
          final total = state.subtotal - state.discount + deliveryFee;
          
          emit(state.copyWith(
            addresses: updatedAddresses,
            selectedAddress: selectedAddress,
            deliveryFee: deliveryFee,
            total: total,
          ));
        } else {
          emit(state.copyWith(
            addresses: updatedAddresses,
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to update address: $e',
      ));
    }
  }

  void _onDeleteAddress(
    DeleteAddress event,
    Emitter<CheckoutState> emit,
  ) {
    try {
      final addressId = event.addressId;
      final updatedAddresses = List<UserAddress>.from(state.addresses)
        ..removeWhere((address) => address.id == addressId);
      
      // If deleted address was selected, select another address
      if (state.selectedAddress?.id == addressId) {
        final newSelectedAddress = updatedAddresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => updatedAddresses.first,
        );
        
        // Recalculate delivery fee based on selected address
        final deliveryFee = newSelectedAddress.pincode == '110001' ? 0.0 : 40.0;
        final total = state.subtotal - state.discount + deliveryFee;
        
        emit(state.copyWith(
          addresses: updatedAddresses,
          selectedAddress: newSelectedAddress,
          deliveryFee: deliveryFee,
          total: total,
        ));
      } else {
        emit(state.copyWith(
          addresses: updatedAddresses,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Failed to delete address: $e',
      ));
    }
  }
  
  // Mock data methods
  List<UserAddress> _getMockAddresses() {
    return [
      UserAddress(
        id: '1',
        name: 'Ajay Kumar',
        phone: '9876543210',
        address: '123, Green Avenue, Sector 14, Delhi',
        pincode: '110001',
        type: 'home',
        isDefault: true,
      ),
      UserAddress(
        id: '2',
        name: 'Ajay Kumar',
        phone: '9876543210',
        address: '456, Blue Street, Connaught Place, Delhi',
        pincode: '110002',
        type: 'work',
        isDefault: false,
      ),
    ];
  }
  
  List<PaymentMethod> _getMockPaymentMethods() {
    return [
      PaymentMethod(
        id: 0,
        name: 'Cash on Delivery',
        icon: '${AppConstants.assetsImagesPath}cod.png',
      ),
      PaymentMethod(
        id: 1,
        name: 'Credit/Debit Card',
        icon: '${AppConstants.assetsImagesPath}card.png',
      ),
      PaymentMethod(
        id: 2,
        name: 'UPI',
        icon: '${AppConstants.assetsImagesPath}upi.png',
      ),
    ];
  }
}