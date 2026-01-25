import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl: ^0.18.0 to pubspec.yaml if needed for date formatting
// import '../core/routes.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form State
  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  // Mock Data for Dropdown
  final List<String> _bookingTypes = [
    'Marriage Ceremony',
    'Baptism',
    'Prayer Hall Meeting',
    'Counseling Session',
    'Community Hall Event',
    'Other'
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- Logic: Submit Form ---
  void _submitBooking() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      setState(() => _isLoading = true);

      // Simulate network request
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a date and time"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text("Request Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Your booking request has been submitted to the admin. You will receive a notification once it is approved.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to Bookings Screen
            },
            child: const Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // --- Logic: Pickers ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D3A99),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D3A99),
              secondary: Color(0xFF9B59B6),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("New Request"),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Booking Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // 1. Booking Type Dropdown
              _buildLabel("Event Type"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _fieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: const Text("Select event type"),
                    value: _selectedType,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5D3A99)),
                    items: _bookingTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                    validator: (val) => val == null ? 'Please select a type' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Date"),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF5D3A99)),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Time"),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Color(0xFF5D3A99)),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedTime == null
                                      ? "Select Time"
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime == null ? Colors.grey[600] : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Purpose / Description
              _buildLabel("Purpose / Notes"),
              Container(
                decoration: _fieldDecoration(),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Describe your event briefly...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter a description';
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 40),

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: const Color(0xFF5D3A99).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          "Submit Request",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}