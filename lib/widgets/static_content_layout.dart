import 'package:flutter/material.dart';

class StaticContentLayout extends StatelessWidget {
  final String title;
  final String? subtitle; // Added for better context
  final List<Widget> children;

  const StaticContentLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Subtle gradient to match the Splash Screen vibe
          gradient: LinearGradient(
            colors: [
              const Color(0xFF5D3A99).withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ...children,
              const SizedBox(height: 40), // Bottom padding for comfort
            ],
          ),
        ),
      ),
    );
  }
} 