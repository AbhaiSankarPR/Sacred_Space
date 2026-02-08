import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added import
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

  final List<Map<String, String>> dummyChurches = [
    {'code': 'CH001', 'name': 'St. Mary Church'},
    {'code': 'CH002', 'name': 'Sacred Heart Church'},
    {'code': 'CH003', 'name': 'Holy Trinity Church'},
  ];

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!; // Context-based localizations

    if (_selectedChurchCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectChurchError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillFieldsError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        churchCode: _selectedChurchCode!,
      );

      final role = user.role;

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/$role', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final l10n = AppLocalizations.of(context)!; // Localizations accessor
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = theme.hintColor;

    InputDecoration inputDecor(String label, String hint) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: hintColor),
        hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3A99).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.church,
                    color: Color(0xFF5D3A99),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.welcomeTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.signInSubtitle,
                  style: TextStyle(color: hintColor),
                ),
                const SizedBox(height: 30),
                Autocomplete<Map<String, String>>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable.empty();
                    return dummyChurches.where(
                      (church) =>
                          church['name']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                          church['code']!.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                    );
                  },
                  displayStringForOption: (option) => "${option['name']} (${option['code']})",
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: textColor),
                      decoration: inputDecor(l10n.church, l10n.enterChurch),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? Colors.white12 : Colors.transparent),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - 88,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (ctx, i) => Divider(
                                height: 1,
                                color: isDark ? Colors.white10 : Colors.grey[200],
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    "${option['name']}",
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    "${option['code']}",
                                    style: TextStyle(color: theme.hintColor),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (selection) => _selectedChurchCode = selection['code'],
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
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(l10n.signIn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccount, style: TextStyle(color: hintColor)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.signup),
                      child: Text(
                        l10n.signUp,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D3A99)),
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