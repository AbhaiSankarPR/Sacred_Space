import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/routes.dart';
import './aboutscreen_service.dart';
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Sacred Space Inquiry',
    );
    if (!await launchUrl(emailUri)) {
      debugPrint('Could not launch email to $email');
    }
  }

  void _showCompanyInfo(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.cardColor,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.8,
            minChildSize: 0.4,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D3A99).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Color(0xFF5D3A99),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sandox Solutions",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Founded by Sandox Team",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Company Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sandox Solutions develops innovative digital solutions focused on community management, security technology, and social impact. The company aims to bridge technology and community services through reliable and user-friendly applications.",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.language,
                        title: "Website",
                        value: "www.sacredspace.app",
                        isDark: isDark,
                        onTap: () => _launchUrl("www.sacredspace.app"),
                      ),
                      _buildContactItem(
                        icon: Icons.email_outlined,
                        title: "Contact Email",
                        value: "support@sacredspace.app",
                        isDark: isDark,
                        onTap: () => _launchEmail("support@sacredspace.app"),
                      ),
                      _buildContactItem(
                        icon: Icons.location_on_outlined,
                        title: "Location",
                        value: "Kerala, India",
                        isDark: isDark,
                        onTap: null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF5D3A99), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            onTap != null
                                ? const Color(0xFF5D3A99)
                                : (isDark ? Colors.white70 : Colors.black87),
                        decoration:
                            onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateUsSheet(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.cardColor,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Pushes sheet over keyboard
        ),
        child: _RateUsSheet(isDark: isDark, theme: theme),
      ),
    );
  }

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
        title: Text(
          loc.aboutApp,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              child: Image.asset(
                'assets/Logo2.png',
                height: 80,
                fit: BoxFit.contain,
              ),
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
              style: TextStyle(fontSize: 15, height: 1.5, color: subTextColor),
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
                    title: "Company Name",
                    subtitle: "Sandox Solutions",
                    textColor: textColor,
                    onTap: () => _showCompanyInfo(context, theme, isDark),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: loc.privacyPolicy,
                    textColor: textColor,
                    onTap:
                        () =>
                            Navigator.pushNamed(context, Routes.privacyPolicy),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  _LinkTile(
                    icon: Icons.description_outlined,
                    title: loc.termsOfService,
                    textColor: textColor,
                    onTap:
                        () =>
                            Navigator.pushNamed(context, Routes.termsOfService),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  _LinkTile(
                    icon: Icons.star_border_rounded,
                    title: loc.rateUs,
                    textColor: textColor,
                    onTap: () => _showRateUsSheet(context, theme, isDark),
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
                height: 1.5,
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontSize: 12))
              : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}

class _RateUsSheet extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _RateUsSheet({required this.isDark, required this.theme});

  @override
  State<_RateUsSheet> createState() => _RateUsSheetState();
}

class _RateUsSheetState extends State<_RateUsSheet> {
  int _selectedRating = 0;
  late final TextEditingController _reviewController;
  final RatingService _ratingService = RatingService();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewController.dispose(); // Clears memory leak!
    super.dispose();
  }

  Future<void> _handleRatingSubmission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final successMessage = await _ratingService.postRating(
        _selectedRating,
        _reviewController.text,
      );

      if (!mounted) return;
      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF5D3A99),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Submission failed. Please try again later."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final titleColor = widget.isDark ? Colors.white : Colors.black87;
    final messageColor = widget.isDark ? Colors.white70 : Colors.grey[700];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Enjoying Sacred Space?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your feedback helps us improve and serve the parish community better. Please consider rating us and sharing your experience.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: messageColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _selectedRating;
              return IconButton(
                icon: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  color: isFilled ? const Color(0xFFF39C12) : Colors.grey[400],
                  size: 36,
                ),
                onPressed: _isLoading 
                    ? null 
                    : () {
                        setState(() {
                          _selectedRating = starIndex;
                        });
                      },
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            enabled: !_isLoading, // Disable editing while loading
            decoration: InputDecoration(
              hintText: "Tell us more about your experience...",
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[350]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[350]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5D3A99), width: 1.5),
              ),
              filled: true,
              fillColor: widget.isDark ? Colors.grey[800] : Colors.grey[50],
            ),
            style: TextStyle(color: titleColor),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[350]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Later",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white70 : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedRating > 0 && !_isLoading) 
                      ? _handleRatingSubmission 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    disabledBackgroundColor: const Color(
                      0xFF5D3A99,
                    ).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Rate Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading 
                ? null 
                : () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.support);
                  },
            child: const Text(
              "Send Feedback",
              style: TextStyle(
                color: Color(0xFF5D3A99),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
