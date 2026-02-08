import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.aboutApp, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- 1. App Logo & Version ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.church, size: 60, color: Color(0xFF5D3A99)),
            ),
            const SizedBox(height: 24),
            Text(
              "Sacred Space",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5D3A99).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                loc.appVersion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D3A99),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- 2. Description ---
            Text(
              loc.appDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: subTextColor,
              ),
            ),

            const SizedBox(height: 40),

            // --- 3. Links Section ---
            Container(
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
                  _LinkTile(
                    icon: Icons.language,
                    title: loc.website,
                    subtitle: "www.sacredspace.com",
                    textColor: textColor,
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: loc.privacyPolicy,
                    textColor: textColor,
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  _LinkTile(
                    icon: Icons.description_outlined,
                    title: loc.termsOfService,
                    textColor: textColor,
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  _LinkTile(
                    icon: Icons.star_border_rounded,
                    title: loc.rateUs,
                    textColor: textColor,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- 4. Footer ---
            Text(
              loc.allRightsReserved,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color textColor;

  const _LinkTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5D3A99), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}