import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/locale_provider.dart'; 

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
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

      // Simulate network request to your backend
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseSelectDateTime),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(loc.requestSent, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(loc.bookingSuccessMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); 
                },
                child: Text(loc.ok, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11, letterSpacing: 1),
      ),
    );
  }

  BoxDecoration _fieldDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        title: Text(loc.newRequest, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(loc.eventType),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                hint: Text(loc.selectEventType),
                value: _selectedType,
                items: bookingTypes.map((type) => DropdownMenuItem(
                  value: type['val'], 
                  child: Text(type['label']!),
                )).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (val) => val == null ? loc.typeRequired : null,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(loc.date),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 20, color: Color(0xFF5D3A99)),
                                const SizedBox(width: 8),
                                Text(_selectedDate == null ? loc.selectDate : DateFormat.yMMMd(localeProvider.locale.languageCode).format(_selectedDate!)),
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
                        _buildLabel(loc.time),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null) setState(() => _selectedTime = picked);
                          },
                          child: Container(
                            height: 56,
                            decoration: _fieldDecoration(theme),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Color(0xFF5D3A99)),
                                const SizedBox(width: 8),
                                Text(_selectedTime == null ? loc.selectTime : _selectedTime!.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel(loc.purposeNotes),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: loc.describeEvent,
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => (val == null || val.isEmpty) ? loc.fieldRequired : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(loc.submitRequest, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}