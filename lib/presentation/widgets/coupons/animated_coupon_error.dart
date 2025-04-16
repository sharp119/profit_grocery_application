import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedCouponError extends StatefulWidget {
  final String errorMessage;
  final double spacing;
  final double smallFontSize;
  final double iconSize;
  final Duration displayDuration;
  final Duration fadeDuration;

  const AnimatedCouponError({
    Key? key,
    required this.errorMessage,
    required this.spacing,
    required this.smallFontSize,
    required this.iconSize,
    this.displayDuration = const Duration(seconds: 4),
    this.fadeDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AnimatedCouponError> createState() => _AnimatedCouponErrorState();
}

class _AnimatedCouponErrorState extends State<AnimatedCouponError> {
  late bool _visible;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _visible = true;
    
    // Start timer to fade out the error message
    _timer = Timer(widget.displayDuration, () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.fadeDuration,
      onEnd: () {
        // Animation completed callback - you can add code here if needed
      },
      child: Padding(
        padding: EdgeInsets.only(top: widget.spacing),
        child: Container(
          padding: EdgeInsets.all(widget.spacing / 2),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: widget.iconSize * 0.8,
              ),
              SizedBox(width: widget.spacing / 2),
              Expanded(
                child: Text(
                  widget.errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: widget.smallFontSize * 0.9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
