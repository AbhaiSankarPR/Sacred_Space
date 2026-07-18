import 'package:flutter/material.dart';
import '../widgets/static_content_layout.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StaticContentLayout(
      title: "Terms of Service",
      children: [
        Text(
          "Last Updated: February 2026",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 20),
        const TermsSection(
          title: "1. Acceptance",
          body: "By using Sacred Space, users agree to comply with these terms.",
        ),
        const TermsSection(
          title: "2. User Responsibilities",
          body: "Users shall:",
          bullets: [
            "Provide accurate information",
            "Maintain account security",
            "Use the platform respectfully",
            "Avoid misuse or unauthorized access",
          ],
        ),
        const TermsSection(
          title: "3. Prohibited Activities",
          body: "The following activities are strictly prohibited:",
          bullets: [
            "Unauthorized access attempts",
            "Distribution of harmful content",
            "Misrepresentation of identity",
            "Disruption of church operations",
          ],
        ),
        const TermsSection(
          title: "4. Service Availability",
          body: "The service is provided on a best-effort basis and may undergo maintenance or updates.",
        ),
        const TermsSection(
          title: "5. Account Termination",
          body: "Accounts may be suspended or terminated for violations of these terms.",
        ),
        const TermsSection(
          title: "6. Limitation of Liability",
          body: "Sacred Space is not responsible for losses resulting from user misuse, technical interruptions, or events beyond reasonable control.",
        ),
      ],
    );
  }
}

class TermsSection extends StatelessWidget {
  final String title;
  final String body;
  final List<String>? bullets;

  const TermsSection({
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
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 8),
            ...bullets!.map((bullet) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D3A99),
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
