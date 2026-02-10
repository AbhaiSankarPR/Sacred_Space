import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(loc.personalInformation),
        centerTitle: true,
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoGroup(theme, "Basic Details", [
              _InfoRow(label: "Full Name", value: user.name, icon: Icons.badge_outlined),
              _InfoRow(label: "Email Address", value: user.email, icon: Icons.email_outlined),
              _InfoRow(label: "Phone Number", value: user.phone ?? "Not provided", icon: Icons.phone_android),
            ]),
            const SizedBox(height: 24),
            _buildInfoGroup(theme, "Profile Information", [
              _InfoRow(label: "Gender", value: user.gender ?? "Not provided", icon: Icons.person_outline),
              _InfoRow(
                label: "Date of Birth", 
                value: user.dob != null ? DateFormat('dd MMMM yyyy').format(DateTime.parse(user.dob!)) : "Not provided", 
                icon: Icons.cake_outlined
              ),
            ]),
            const SizedBox(height: 24),
            _buildInfoGroup(theme, "Residence", [
              _InfoRow(label: "Residence Type", value: user.residenceType ?? "Not provided", icon: Icons.night_shelter_outlined),
              _InfoRow(label: "House Name", value: user.houseName ?? "Not provided", icon: Icons.home_outlined),
              _InfoRow(label: "House Number", value: user.houseNumber ?? "Not provided", icon: Icons.numbers_outlined),
              _InfoRow(label: "Permanent Address", value: user.permanentAddress ?? "Not provided", icon: Icons.location_on_outlined),
            ]),
            const SizedBox(height: 24),
            _buildInfoGroup(theme, "Church Membership", [
              _InfoRow(label: "Assigned Church", value: user.churchName, icon: Icons.church_outlined),
              _InfoRow(label: "Church Location", value: user.location, icon: Icons.map_outlined),
              _InfoRow(label: "Access Level", value: user.role.toUpperCase(), icon: Icons.verified_user_outlined),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGroup(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5D3A99), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}