import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _houseNoController;
  late TextEditingController _houseNameController;

  String? _selectedGender;
  String? _selectedResidence;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;

    // 1. Logic for Gender normalization
    if (user?.gender == "MALE") {
      _selectedGender = "MALE";
    } else if (user?.gender == "FEMALE") {
      _selectedGender = "FEMALE";
    } else if (user?.gender == "OTHER") {
      _selectedGender = "OTHER";
    } else {
      _selectedGender = user?.gender;
    }

    if (user?.residenceType == "OWNED" || user?.residenceType == "Own") {
  _selectedResidence = "Own";
} else if (user?.residenceType == "RENTED" || user?.residenceType == "Rented") {
  _selectedResidence = "Rented";
} else {
  _selectedResidence = user?.residenceType;
}

    // 2. Initialize Controllers
    _nameController = TextEditingController(text: user?.name ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _addressController = TextEditingController(text: user?.permanentAddress ?? "");
    _houseNoController = TextEditingController(text: user?.houseNumber ?? "");
    _houseNameController = TextEditingController(text: user?.houseName ?? "");

    _selectedResidence = user?.residenceType;

    // 3. Safe Date Parsing
    final String? dobString = user?.dob;
    _selectedDob = dobString != null ? DateTime.tryParse(dobString) : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _houseNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _authService.updateProfile(
        name: _nameController.text.trim(),
        gender: _selectedGender ?? "",
        dob: _selectedDob?.toIso8601String() ?? "",
        permanentAddress: _addressController.text.trim(),
        houseNumber: _houseNoController.text.trim(),
        residenceType: _selectedResidence ?? "",
        houseName: _houseNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel("Basic Information", theme),
              _buildTextField(label: "Name", controller: _nameController, icon: Icons.person_outline, theme: theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: "Gender",
                      value: _selectedGender,
                      items: ["MALE", "FEMALE", "OTHER"],
                      onChanged: (val) => setState(() => _selectedGender = val),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePickerTile(theme)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(label: "Phone", controller: _phoneController, icon: Icons.phone_android, theme: theme, keyboardType: TextInputType.phone),
              const SizedBox(height: 32),
              _buildSectionLabel("Residence Details", theme),
              _buildDropdownField(
  label: "Residence Type",
  value: ["Own", "Rented", "Lease"].contains(_selectedResidence) 
      ? _selectedResidence 
      : null,
  items: ["Own", "Rented", "Lease"], // Ensure "Own" matches the logic above
  onChanged: (val) => setState(() => _selectedResidence = val),
  theme: theme,
),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: "House No", controller: _houseNoController, theme: theme)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(label: "House Name", controller: _houseNameController, theme: theme)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(label: "Permanent Address", controller: _addressController, theme: theme, maxLines: 3),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE PROFILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D3A99))),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, IconData? icon, required ThemeData theme, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5D3A99), size: 20) : null,
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged, required ThemeData theme}) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: theme.cardColor,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDatePickerTile(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDob ?? DateTime(2000),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (d != null) setState(() => _selectedDob = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DOB", style: TextStyle(fontSize: 12, color: theme.hintColor)),
            const SizedBox(height: 4),
            Text(
              _selectedDob == null ? "Select Date" : DateFormat.yMd().format(_selectedDob!),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}