import 'package:flutter/material.dart';
import '../widgets/static_content_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticContentLayout(
      title: "Privacy Policy",
      children: [
        const Text("Last Updated: February 2026", style: TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        const PolicySection(
          title: "1. Information We Collect",
          body: "We collect personal information that you provide to us, including your name, email address, phone number, date of birth, and residence details. This information is required to verify your identity and facilitate church services.",
        ),
        const PolicySection(
          title: "2. How We Use Your Information",
          body: "Your data is used to manage your church membership, process booking requests, and send important announcements. We do not sell your personal data to third parties.",
        ),
        const PolicySection(
          title: "3. Data Security",
          body: "We implement industry-standard security measures, including Bearer Token authentication and encrypted storage, to protect your personal information from unauthorized access.",
        ),
        const PolicySection(
          title: "4. Your Rights",
          body: "You have the right to access, correct, or request the deletion of your personal data at any time via the Profile settings within the app.",
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "For questions, contact: support@sacredspace.com",
            style: TextStyle(color: Color(0xFF5D3A99), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const PolicySection({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }
}