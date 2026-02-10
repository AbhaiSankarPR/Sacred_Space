import 'package:flutter/material.dart';
import '../widgets/static_content_layout.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentLayout(
      title: "About Us",
      children: [
        Center(
          child: Column(
            children: [
              const Icon(Icons.church, size: 80, color: Color(0xFF5D3A99)),
              const SizedBox(height: 16),
              const Text(
                "Sacred Space",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D3A99)),
              ),
              Text("Version 1.0.0", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text("Our Mission", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "Sacred Space is a digital platform designed to bridge the gap between the church and its community. Our mission is to provide a seamless way for members to stay connected, request services, and grow in faith through modern technology.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text("What We Offer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const BulletItem(text: "Easy booking for church services and sacraments."),
        const BulletItem(text: "Real-time announcements and emergency alerts."),
        const BulletItem(text: "Integrated community events calendar."),
        const BulletItem(text: "Secure digital scrapbook of your spiritual journey."),
      ],
    );
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D3A99))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}