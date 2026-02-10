import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart'; 
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

  // Controllers
  late TextEditingController _nameController;
  final _addressController = TextEditingController();
  final _houseNumController = TextEditingController();
  final _houseNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedResidence;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Pre-fill the name from the AuthService user object
    _nameController = TextEditingController(text: _auth.currentUser?.name ?? '');
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5D3A99)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your date of birth")),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.updateProfile(
        name: _nameController.text.trim(),
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
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _houseNumController.dispose();
    _houseNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = _auth.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(loc.completeProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display existing User Info
              _buildUserSummary(user, isDark),
              const SizedBox(height: 24),
              
              _buildSectionTitle("Personal Details"),
              _buildCard([
                _buildTextField(_nameController, "Full Name", Icons.badge_outlined),
                const Divider(),
                _buildDropdown("Gender", ['MALE', 'FEMALE', 'OTHER'], Icons.person_outline, (val) => _selectedGender = val),
                const Divider(),
                _buildDatePicker(theme),
                const Divider(),
                _buildTextField(_phoneController, "Phone Number", Icons.phone_android, kType: TextInputType.phone),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle("Residence & Address"),
              _buildCard([
                _buildDropdown("Residence Type", ['OWNED', 'RENTED'], Icons.night_shelter_outlined, (val) => _selectedResidence = val),
                const Divider(),
                _buildTextField(_houseNameController, "House Name", Icons.home_outlined),
                const Divider(),
                _buildTextField(_houseNumController, "House Number", Icons.numbers_outlined),
                const Divider(),
                _buildTextField(_addressController, "Permanent Address", Icons.location_on_outlined, maxLines: 2),
              ]),

              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(loc.saveAndContinue, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSummary(User? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5D3A99).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5D3A99).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF5D3A99),
            radius: 25,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? "U",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.email ?? "", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  "Joined ${user?.churchName ?? 'Church'}", 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF5D3A99))),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.withOpacity(0.2))
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return InkWell(
      onTap: _pickDate,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: Color(0xFF5D3A99)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date of Birth", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  _selectedDate == null ? "Select Date" : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType kType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF5D3A99), size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF5D3A99), size: 22),
        border: InputBorder.none,
      ),
      items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }
}