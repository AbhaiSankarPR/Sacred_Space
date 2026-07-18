import 'package:flutter/material.dart';
import '../widgets/static_content_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StaticContentLayout(
      title: "Privacy Policy",
      children: [
        Text(
          "Last Updated: February 2026",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodySmall?.color, // Themed italic text
          ),
        ),
        const SizedBox(height: 20),
        const PolicySection(
          title: "1. Information We Collect",
          body: "We collect the following personal and device information:",
          bullets: [
            "Name",
            "Email Address",
            "Phone Number",
            "Parish Information",
            "Booking Information",
            "Device Information",
          ],
        ),
        const PolicySection(
          title: "2. How We Use Information",
          body: "Your information is used for the following purposes:",
          bullets: [
            "Account Management",
            "Appointment Scheduling",
            "Facility Bookings",
            "Notifications and Announcements",
            "Technical Support",
            "Security Monitoring",
          ],
        ),
        const PolicySection(
          title: "3. Data Protection",
          body: "We implement industry-standard security measures to protect user information from unauthorized access, disclosure, alteration, or destruction.",
        ),
        const PolicySection(
          title: "4. Third-Party Sharing",
          body: "User information is never sold. Data may be shared only when required for app functionality or legal compliance.",
        ),
        const PolicySection(
          title: "5. User Rights",
          body: "Users may:",
          bullets: [
            "View their personal data",
            "Request corrections",
            "Request account deletion",
            "Withdraw consent where applicable",
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "For questions, contact: privacy@sacredspace.app",
            style: TextStyle(
              color: Color(0xFF5D3A99), // Brand color usually stays consistent
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final List<String>? bullets;

  const PolicySection({
    super.key,
    required this.title,
    required this.body,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color, // Adapts to Light/Dark
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color, // Adapts to Light/Dark
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 8),
            ...bullets!.map((bullet) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "• ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D3A99),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}