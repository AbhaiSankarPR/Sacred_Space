import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

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
        SnackBar(
          content: const Text("Please select a date and time"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        // Dialog background color handled by theme
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
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: const Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // --- Logic: Pickers (Updated for Theme) ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      // Theme is automatically handled by MaterialApp now, no need for manual override
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Access dynamic theme data
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // Background handled by theme
      appBar: AppBar(
        title: const Text("New Request"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),

              // 1. Booking Type Dropdown
              _buildLabel("Event Type"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _fieldDecoration(theme),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: theme.cardColor, // Fix dropdown background
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: Text("Select event type", style: TextStyle(color: theme.hintColor)),
                    value: _selectedType,
                    icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
                    items: _bookingTypes.map((type) {
                      return DropdownMenuItem(
                        value: type, 
                        child: Text(type, style: TextStyle(color: textColor)),
                      );
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
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate == null
                                      ? "Select Date"
                                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null ? theme.hintColor : textColor,
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
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedTime == null
                                      ? "Select Time"
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime == null ? theme.hintColor : textColor,
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
                decoration: _fieldDecoration(theme),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Describe your event briefly...",
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.4),
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
        // Use standard grey for labels in both modes
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }

  BoxDecoration _fieldDecoration(ThemeData theme) {
    return BoxDecoration(
      // Dynamic Card Color (White vs Dark Grey)
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}