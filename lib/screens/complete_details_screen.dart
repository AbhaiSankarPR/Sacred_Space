import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';

class CompleteDetailsScreen extends StatefulWidget {
  const CompleteDetailsScreen({super.key});

  @override
  State<CompleteDetailsScreen> createState() => _CompleteDetailsScreenState();
}

class _CompleteDetailsScreenState extends State<CompleteDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  bool _loading = false;

  // Controllers for the new params
  final _addressController = TextEditingController();
  final _houseNumController = TextEditingController();
  final _houseNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedResidence;
  DateTime? _selectedDate;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.updateProfile(
        name: _auth.currentUser!.name,
        gender: _selectedGender!,
        dob: _selectedDate!.toIso8601String(),
        permanentAddress: _addressController.text.trim(),
        houseNumber: _houseNumController.text.trim(),
        residenceType: _selectedResidence!,
        houseName: _houseNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/${_auth.currentUser?.role}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.completeProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdown("Gender", ['MALE', 'FEMALE', 'OTHER'], (val) => _selectedGender = val),
              const SizedBox(height: 16),
              _buildDropdown("Residence", ['OWNED', 'RENTED'], (val) => _selectedResidence = val),
              const SizedBox(height: 16),
              _buildTextField(_houseNameController, "House Name", Icons.home),
              const SizedBox(height: 16),
              _buildTextField(_houseNumController, "House Number", Icons.numbers),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Permanent Address", Icons.map),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone", Icons.phone, kType: TextInputType.phone),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : Text(loc.saveAndContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for cleaner code
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType kType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }
}