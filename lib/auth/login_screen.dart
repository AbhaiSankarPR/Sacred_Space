import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _selectedChurchCode;
  bool _loading = false;
  
  // This will hold the real data from your /churches endpoint
  List<Map<String, String>> _liveChurches = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// Fetches the church list from the backend on load
  Future<void> _fetchInitialData() async {
    try {
      final churches = await _authService.getChurches();
      if (mounted) {
        setState(() {
          _liveChurches = churches;
        });
      }
    } catch (e) {
      // Handle potential fetch errors (e.g., offline)
      debugPrint("Failed to load churches: $e");
    }
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedChurchCode == null) {
      _showSnackBar(l10n.selectChurchError, isError: true);
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(l10n.fillFieldsError, isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        churchCode: _selectedChurchCode!,
      );

      // The role is now lowercased in AuthService for route compatibility
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/${user.role}', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = theme.hintColor;

    InputDecoration inputDecor(String label, String hint) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5D3A99), width: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.church, color: Color(0xFF5D3A99), size: 60),
                const SizedBox(height: 16),
                Text(l10n.welcomeTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 30),

                // AUTOCOMPLETE CONNECTED TO BACKEND
                Autocomplete<Map<String, String>>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return _liveChurches.where((church) =>
                        church['name']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                        church['code']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => option['name']!,
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: textColor),
                      decoration: inputDecor(l10n.church, l10n.enterChurch),
                    );
                  },
                  onSelected: (selection) {
                    _selectedChurchCode = selection['code']; // This is the ID (e.g. ST_MARYS_TVM)
                  },
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  decoration: inputDecor(l10n.email, l10n.enterEmail),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: inputDecor(l10n.password, l10n.enterPassword),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D3A99),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccount, style: TextStyle(color: hintColor)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.signup),
                      child: const Text(
                        "Sign Up", // Hardcoded for example, use l10n.signUp
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D3A99)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}