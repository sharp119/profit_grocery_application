import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../home/home_page.dart'; // Ensure this import is correct
import '../main_navigation.dart'; // Ensure this import is correct for homeRoute
import 'phone_entry_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late Timer _authTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    _authTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<AuthBloc>().add(const CheckAuthStatus());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppConstants.homeRoute, // Assuming homeRoute leads to MainNavigation or similar
            (route) => false,
          );
        } else if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PhoneEntryPage()),
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Authentication check failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const PhoneEntryPage()),
              );
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // MODIFIED PART: Show actual logo
                      // TODO: Replace 'assets/images/app_logo.png' with the actual path to your logo
                      // TODO: Ensure your logo asset is declared in pubspec.yaml
                      Image.asset(
                        'assets/icon/play_store_512.png', // <<< YOUR LOGO PATH HERE
                        width: 250.w,
                        height: 250.w,
                        // You might want to add fit: BoxFit.contain or similar
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // Text(
                      //   AppConstants.appName,
                      //   style: TextStyle(
                      //     color: AppTheme.accentColor,
                      //     fontSize: 36.sp,
                      //     fontWeight: FontWeight.bold,
                      //     letterSpacing: 1.2,
                      //   ),
                      // ),
                      
                      // SizedBox(height: 16.h),
                      
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      SizedBox(height: 80.h),
                      
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                          strokeWidth: 3.w,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}