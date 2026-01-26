import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Mock FAQs
  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do I book a facility?',
      'answer': 'Go to the "Bookings" tab in the dashboard, click "New Booking", select your event type, date, and time, and submit your request.'
    },
    {
      'question': 'Can I edit my profile?',
      'answer': 'Yes, go to the "Profile" tab. Currently, you can view your details. Editing capability will be enabled in the next update.'
    },
    {
      'question': 'How do I reset my password?',
      'answer': 'You can reset your password from the "Settings" menu under "Account", or use the "Forgot Password" link on the login screen.'
    },
    {
      'question': 'Who sees my emergency alerts?',
      'answer': 'Emergency alerts are broadcasted immediately to all registered Church Admins and Priests.'
    },
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Header Text ---
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "How can we help you?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select an option below or browse our FAQs",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. Contact Grid ---
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.call,
                    title: "Call Us",
                    color: Colors.green,
                    isDark: isDark,
                    onTap: () => _launchUrl("tel:+1234567890"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email_outlined,
                    title: "Email",
                    color: Colors.orange,
                    isDark: isDark,
                    onTap: () => _launchUrl("mailto:support@sacredspace.com"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.language,
                    title: "Website",
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: () => _launchUrl("https://www.google.com"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 3. FAQs Section ---
            Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: Colors.white10) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      faq['answer']!,
                      style: TextStyle(color: subTextColor, height: 1.4),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 30),

            // --- 4. Feedback Form ---
            Text(
              "Send us a Message",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Describe your issue or feedback...",
                      hintStyle: TextStyle(color: theme.hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5D3A99)),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D3A99),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Feedback sent successfully!")),
                        );
                      },
                      child: const Text("Submit Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}