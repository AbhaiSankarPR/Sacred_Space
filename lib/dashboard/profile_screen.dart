import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import '../screens/aboutUsScreen.dart';
import '../screens/personal_info_screen.dart';
import '../screens/PrivacyPolicyScreen.dart';
import '../widgets/water_drop_notification.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadProfilePic() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      if (!mounted) return;
      final authService = context.read<AuthService>();
      await authService.updateProfilePicture(result.files.first);

      if (!mounted) return;
      final overlayState = Overlay.of(context);
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder:
            (context) => WaterDropNotification(
              message: loc.profilePicUpdated,
              onDismiss: () => overlayEntry.remove(),
            ),
      );
      overlayState.insert(overlayEntry);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Bind reactively to updates in AuthService
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) {
      // Safety redirect if session is lost
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.myProfile,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.pushNamed(context, Routes.editProfile);
            },
          ),
        ],
      ),
      drawer: AppDrawer(user: user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- PROFILE HEADER CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5D3A99).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[100],
                          // Use user's specific profile image if available, else fallback to initials or icon
                          backgroundImage:
                              (user.profilePicUrl != null &&
                                      user.profilePicUrl!.isNotEmpty)
                                  ? NetworkImage(user.profilePicUrl!)
                                  : (user.logoUrl != null &&
                                      user.logoUrl!.isNotEmpty)
                                  ? NetworkImage(user.logoUrl!)
                                  : null,
                          child:
                              _isUploading
                                  ? const CircularProgressIndicator(
                                    color: Color(0xFF5D3A99),
                                  )
                                  : (user.profilePicUrl == null ||
                                          user.profilePicUrl!.isEmpty) &&
                                      (user.logoUrl == null ||
                                          user.logoUrl!.isEmpty)
                                  ? const Icon(
                                    Icons.person,
                                    size: 45,
                                    color: Color(0xFF5D3A99),
                                  )
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadProfilePic,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D3A99),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.cardColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name, // Displaying User's name instead of Church name here
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: user.inviteCode ?? ""),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.inviteCodeCopied)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${loc.inviteCode}: ${user.inviteCode ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy, size: 14, color: subTextColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3A99).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D3A99),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- MENU SECTIONS ---
            _buildSectionTitle(loc.accountSettings, theme),
            _buildMenuCard(theme, [
              _ProfileMenuTile(
                icon: Icons.person_outline,
                title: loc.personalInformation,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.lock_outline,
                title: loc.changePassword,
                onTap: () {
                  Navigator.pushNamed(context, Routes.changePassword);
                },
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionTitle(loc.appInfo, theme),
            _buildMenuCard(theme, [
              _ProfileMenuTile(
                icon: Icons.info_outline,
                title: loc.aboutUs,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    ),
              ),
              _ProfileMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: loc.privacyPolicy,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
              ),
            ]),

            const SizedBox(height: 30),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: Text(
                  loc.logOut,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // Get the token first so the backend can unregister it
    // String? token = await FirebaseMessaging.instance.getToken();
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('deviceToken');
    print(token);
    AuthService().logout(token);
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(ThemeData theme, List<Widget> children) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF5D3A99).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5D3A99), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
