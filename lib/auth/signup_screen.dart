import 'package:flutter/material.dart';
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

  // Dummy churches for autocomplete
  final List<Map<String, String>> _dummyChurches = [
    {'code': 'CH001', 'name': 'St. Mary Church'},
    {'code': 'CH002', 'name': 'Sacred Heart Church'},
    {'code': 'CH003', 'name': 'Holy Trinity Church'},
  ];

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedChurchCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a church')),
      );
      return;
    }

    if (!_passwordsMatch()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Dummy signup logic: simulate backend signup
      await Future.delayed(const Duration(seconds: 1));

      // Auto-login after signup (dummy)
      final result = await _auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        churchCode: _selectedChurchCode!,
      );

      final String role = result['role'] as String? ?? 'member';

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/$role',
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup failed')),
      );
    } finally {
      setState(() => _loading = false);
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(
                    Icons.person_add,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Sign up to get started",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    hintText: "Enter your full name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Church selection autocomplete
                Autocomplete<Map<String, String>>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Map<String, String>>.empty();
                    return _dummyChurches.where((church) =>
                        church['name']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                        church['code']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => "${option['name']} (${option['code']})",
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Church",
                        hintText: "Enter church name or code",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Enter your email",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Re-enter your password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Signup button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.login);
                      },
                      child: const Text("Login"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
