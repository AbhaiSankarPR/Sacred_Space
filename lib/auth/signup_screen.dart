import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _auth = AuthService();

  String? _selectedChurchCode;
  bool _loading = false;
  List<Map<String, String>> _churches = [];

  @override
  void initState() {
    super.initState();
    _loadChurches();
  }

  Future<void> _loadChurches() async {
    final list = await _auth.getChurches();
    if (mounted) {
      setState(() => _churches = list);
    }
  }

  bool _passwordsMatch() => _passwordController.text == _confirmPasswordController.text;

  Future<void> _signup() async {
    final loc = AppLocalizations.of(context)!;

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedChurchCode == null) {
      _showSnackBar(loc.fillAllFields, isError: true);
      return;
    }

    if (!_passwordsMatch()) {
      _showSnackBar(loc.passwordMismatch, isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        churchId: _selectedChurchCode!,
      );

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  color: isDark ? Colors.black45 : Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person_add, color: theme.colorScheme.primary, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.signupTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildTextField(controller: _nameController, label: loc.fullName, theme: theme),
                const SizedBox(height: 16),

                Autocomplete<Map<String, String>>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return _churches.where((church) =>
                        church['name']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                        church['code']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => "${option['name']} (${option['code']})",
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return _buildTextField(
                      controller: controller,
                      label: loc.church,
                      theme: theme,
                      focusNode: focusNode,
                    );
                  },
                  onSelected: (selection) => _selectedChurchCode = selection['code'],
                ),
                const SizedBox(height: 16),

                _buildTextField(controller: _emailController, label: loc.email, theme: theme),
                const SizedBox(height: 16),

                _buildTextField(controller: _passwordController, label: loc.password, theme: theme, obscure: true),
                const SizedBox(height: 16),

                _buildTextField(controller: _confirmPasswordController, label: loc.confirmPassword, theme: theme, obscure: true),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(loc.signup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.alreadyHaveAccount, style: TextStyle(color: theme.hintColor)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.login),
                      child: Text(loc.login, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    bool obscure = false,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }
}