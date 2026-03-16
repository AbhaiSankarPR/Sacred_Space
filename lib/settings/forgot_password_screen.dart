import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart'; // Still needed for getChurches()
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final  baseUrl = dotenv.env['API_BASE_URL'];
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _selectedChurchId;
  List<Map<String, String>> _churches = [];
  int _step = 1; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChurches();
  }

  Future<void> _loadChurches() async {
    final churches = await _authService.getChurches();
    setState(() => _churches = churches);
  }

  // --- STEP 1: REQUEST OTP (FETCH) ---
  void _requestOtp() async {
    if (_emailController.text.isEmpty || _selectedChurchId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'churchId': _selectedChurchId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _step = 2);
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['message'] ?? "Failed to send OTP", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection error", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- STEP 2: RESET PASSWORD (FETCH) ---
  void _handleFinalReset() async {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length < 6 || _passwordController.text != _confirmPasswordController.text) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'churchId': _selectedChurchId,
          'email': _emailController.text.trim(),
          'otp': otp,
          'newPassword': _passwordController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Password reset successfully!");
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['message'] ?? "Reset failed", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection error", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"), 
        backgroundColor: const Color(0xFF5D3A99), 
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(_step == 1 ? Icons.lock_reset : Icons.mark_email_read, size: 80, color: const Color(0xFF5D3A99)),
            const SizedBox(height: 24),
            Text(_step == 1 ? "Forgot Password?" : "Verify & Reset", 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              _step == 1 ? "Get an OTP on your email" : "Enter OTP and new password",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildInputs(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_step == 1 ? _requestOtp : _handleFinalReset),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_step == 1 ? "SEND CODE" : "RESET PASSWORD", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    if (_step == 1) {
      return Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedChurchId,
            items: _churches.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['name']!))).toList(),
            onChanged: (val) => setState(() => _selectedChurchId = val),
            decoration: InputDecoration(
              labelText: "Select Church", 
              prefixIcon: const Icon(Icons.church), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController, 
            decoration: InputDecoration(
              labelText: "Email Address", 
              prefixIcon: const Icon(Icons.email), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
            )
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (i) => _buildOtpBox(i))),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController, 
            obscureText: true, 
            decoration: InputDecoration(
              labelText: "New Password", 
              prefixIcon: const Icon(Icons.lock), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
            )
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController, 
            obscureText: true, 
            decoration: InputDecoration(
              labelText: "Confirm Password", 
              prefixIcon: const Icon(Icons.lock_clock), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
            )
          ),
        ],
      );
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (v.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
        },
        decoration: InputDecoration(
          filled: true, 
          fillColor: Colors.grey[100], 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
        ),
      ),
    );
  }
}