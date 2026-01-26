import 'package:flutter/material.dart';
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
    if (_selectedChurchCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a church'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
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

      // Navigate to dashboard based on role
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/$role', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login failed. Please check credentials.'),
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
    // Access Dynamic Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = theme.hintColor;

    // Helper for input decoration to reduce boilerplate
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
          borderSide: BorderSide.none, // Cleaner look
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
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic Background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor, // Dynamic Card Background
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
                // Logo Area
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
                  "Welcome to Sacred Space",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Sign in to access your account",
                  style: TextStyle(color: hintColor),
                ),
                const SizedBox(height: 30),

                // Church Autocomplete
                Autocomplete<Map<String, String>>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty)
                      return const Iterable.empty();
                    return dummyChurches.where(
                      (church) =>
                          church['name']!.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ) ||
                          church['code']!.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                    );
                  },
                  displayStringForOption:
                      (option) => "${option['name']} (${option['code']})",
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onEditingComplete,
                  ) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: textColor),
                      decoration: inputDecor(
                        "Church",
                        "Enter church code or name",
                      ),
                    );
                  },
                  // Fix for dropdown menu colors in dark mode
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation:
                            8, // Higher elevation to "float" above everything
                        color:
                            theme
                                .cardColor, // Matches card background (White/DarkGrey)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.white12 : Colors.transparent,
                          ),
                        ),
                        child: ConstrainedBox(
                          // Limit height so it doesn't overflow
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: SizedBox(
                            // Calculation: Screen Width - (Outer Padding 20*2) - (Inner Container Padding 24*2) = 88
                            width: MediaQuery.of(context).size.width - 88,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder:
                                  (ctx, i) => Divider(
                                    height: 1,
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.grey[200],
                                  ),
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense:
                                      true, // Makes items slightly more compact
                                  title: Text(
                                    "${option['name']}",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${option['code']}",
                                    style: TextStyle(color: theme.hintColor),
                                  ),
                                  onTap: () => onSelected(option),
                                  hoverColor: const Color(
                                    0xFF5D3A99,
                                  ).withOpacity(0.1),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (selection) {
                    _selectedChurchCode = selection['code'];
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  decoration: inputDecor("Email", "Enter your email"),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: inputDecor("Password", "Enter your password"),
                ),
                const SizedBox(height: 24),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D3A99),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: const Color(0xFF5D3A99).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _login,
                    child:
                        _loading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: hintColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.signup);
                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D3A99),
                        ),
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
