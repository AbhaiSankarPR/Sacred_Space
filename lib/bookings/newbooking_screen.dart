import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/locale_provider.dart'; // Ensure this path is correct

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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    final loc = AppLocalizations.of(context)!;
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
          content: Text(loc.pleaseSelectDateTime),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            Text(loc.requestSent, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          loc.bookingSuccessMessage,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: Text(loc.ok, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
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
    // Localization and Theme access
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Localized options list
    final List<Map<String, String>> bookingTypes = [
      {'val': 'Marriage', 'label': loc.marriageCeremony},
      {'val': 'Baptism', 'label': loc.baptism},
      {'val': 'Prayer', 'label': loc.prayerMeeting},
      {'val': 'Counseling', 'label': loc.counseling},
      {'val': 'Community', 'label': loc.communityEvent},
      {'val': 'Other', 'label': loc.other},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.newRequest),
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
                loc.bookingDetails,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),

              // 1. Booking Type Dropdown
              _buildLabel(loc.eventType),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _fieldDecoration(theme),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: theme.cardColor,
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: Text(loc.selectEventType, style: TextStyle(color: theme.hintColor, fontSize: 14)),
                    value: _selectedType,
                    icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
                    items: bookingTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['val'], 
                        child: Text(type['label']!, style: TextStyle(color: textColor, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                    validator: (val) => val == null ? loc.typeRequired : null,
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
                        _buildLabel(loc.date),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? loc.selectDate
                                        : DateFormat.yMMMd(localeProvider.locale.languageCode).format(_selectedDate!),
                                    style: TextStyle(
                                      color: _selectedDate == null ? theme.hintColor : textColor,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(loc.time),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTime == null
                                        ? loc.selectTime
                                        : _selectedTime!.format(context),
                                    style: TextStyle(
                                      color: _selectedTime == null ? theme.hintColor : textColor,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              _buildLabel(loc.purposeNotes),
              Container(
                decoration: _fieldDecoration(theme),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 4,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: loc.describeEvent,
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return loc.fieldRequired;
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
                      : Text(
                          loc.submitRequest,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
      ),
    );
  }

  BoxDecoration _fieldDecoration(ThemeData theme) {
    return BoxDecoration(
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