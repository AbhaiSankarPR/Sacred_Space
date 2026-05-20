import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../auth/auth_service.dart';
import '../../widgets/app_drawer.dart';

class SignupRequestsScreen extends StatefulWidget {
  const SignupRequestsScreen({super.key});

  @override
  State<SignupRequestsScreen> createState() => _SignupRequestsScreenState();
}

class _SignupRequestsScreenState extends State<SignupRequestsScreen> {
  List<dynamic> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await AuthService().getPendingSignups();
      if (mounted) {
        setState(() {
          _pendingUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(AppLocalizations.of(context)!.errorOccurred, isError: true);
      }
    }
  }

  Future<void> _handleRequest(String userId, String action) async {
    try {
      await AuthService().handleSignupRequest(userId, action);
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.signupRequestHandled);
        _fetchPendingUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.errorOccurred, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user!),
      appBar: AppBar(
        title: Text(loc.signupRequests, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPendingUsers,
              child: _pendingUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_disabled_outlined, size: 64, color: theme.hintColor),
                          const SizedBox(height: 16),
                          Text(loc.noSignupRequests, style: TextStyle(color: theme.hintColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pendingUsers.length,
                      itemBuilder: (context, index) {
                        final pendingUser = _pendingUsers[index];
                        final profile = pendingUser['profile'] ?? {};
                        final name = profile['name'] ?? pendingUser['name'] ?? 'No Name';
                        final email = pendingUser['email'] ?? 'No Email';
                        final houseName = profile['houseName'] ?? 'No House Name';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                              child: const Icon(Icons.person_add, color: Color(0xFF5D3A99), size: 28),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email, style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                Text(houseName, style: const TextStyle(color: Color(0xFF8E44AD), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Decline Button
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () => _handleRequest(pendingUser['id'], 'reject'),
                                  tooltip: loc.decline,
                                ),
                                const SizedBox(width: 4),
                                // Accept Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _handleRequest(pendingUser['id'], 'approve'),
                                  child: Text(loc.accept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
