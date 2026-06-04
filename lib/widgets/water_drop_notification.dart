import 'package:flutter/material.dart';

class WaterDropNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const WaterDropNotification({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<WaterDropNotification> createState() => _WaterDropNotificationState();
}

class _WaterDropNotificationState extends State<WaterDropNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // 1. Droplet drops down from top
    _dropAnimation = Tween<double>(begin: -100.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInBack),
      ),
    );

    // 2. Droplet expands horizontally to form a card shape
    _morphAnimation = Tween<double>(begin: 60.0, end: 320.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.8, curve: Curves.elasticOut),
      ),
    );

    // 3. Success checkmark and text fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds of showing the success message
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        
        // Morph border radius from asymmetric droplet to symmetric capsule
        final borderRadius = BorderRadius.only(
          topLeft: const Radius.circular(30),
          topRight: const Radius.circular(30),
          bottomLeft: const Radius.circular(30),
          bottomRight: Radius.circular(progress < 0.5 ? 4 : 30),
        );

        return Positioned(
          top: _dropAnimation.value,
          left: MediaQuery.of(context).size.width / 2 - (_morphAnimation.value / 2),
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: const Color(0xFF5D3A99).withValues(alpha: 0.25),
            borderRadius: borderRadius,
            child: Container(
              width: _morphAnimation.value,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D3A99), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
              ),
              child: progress < 0.55
                  ? Center(
                      // Inline drop core
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                widget.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
