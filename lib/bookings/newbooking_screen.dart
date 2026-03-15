import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sacred_space/auth/auth_service.dart';
import 'booking_service.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BookingService();

  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  void _submitBooking() async {
    final auth = AuthService();
    final loc = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      
      setState(() => _isLoading = true);

      final start = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedStartTime!.hour, _selectedStartTime!.minute,
      );

      final end = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedEndTime!.hour, _selectedEndTime!.minute,
      );

      // Validation: End time must be after start time
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorOccurred)), // Or a specific "End time error" key
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        await _service.createBooking({
          "title": _selectedType,
          "description": _noteController.text,
          "startTime": start.toIso8601String(),
          "endTime": end.toIso8601String(),
          "churchId": auth.currentUser?.churchId,
        });

        if (mounted) _showSuccessDialog(loc);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorOccurred)),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(loc.requestSent,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(loc.ok, style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.newRequest),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(loc.eventType),
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: Text(loc.selectEventType),
                items: [
                  DropdownMenuItem(value: "Marriage", child: Text(loc.marriageCeremony)),
                  DropdownMenuItem(value: "Baptism", child: Text(loc.baptism)),
                  DropdownMenuItem(value: "Prayer", child: Text(loc.prayerMeeting)),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                validator: (val) => val == null ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 24),

              _buildSectionLabel(loc.selectDate),
              _buildPickerTile(
                label: loc.selectDate,
                value: _selectedDate == null 
                    ? null 
                    : DateFormat.yMMMd(locale).format(_selectedDate!),
                icon: Icons.calendar_today_rounded,
                isFullWidth: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(loc.startTime),
                        _buildPickerTile(
                          label: loc.selectTime,
                          value: _selectedStartTime?.format(context),
                          icon: Icons.access_time_rounded,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) {
                              setState(() {
                                _selectedStartTime = t;
                                // Auto-set end time to 1 hour later as a suggestion
                                _selectedEndTime = TimeOfDay(hour: t.hour + 1, minute: t.minute);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(loc.endTime),
                        _buildPickerTile(
                          label: loc.selectTime,
                          value: _selectedEndTime?.format(context),
                          icon: Icons.update_rounded,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _selectedStartTime ?? TimeOfDay.now(),
                            );
                            if (t != null) setState(() => _selectedEndTime = t);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionLabel(loc.purposeNotes),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: loc.describeEvent,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
                validator: (val) => (val == null || val.isEmpty) ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
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
                      : Text(loc.submitRequest.toUpperCase(), 
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    final bool hasValue = value != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? const Color(0xFF5D3A99).withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5D3A99), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: hasValue ? Colors.black87 : Colors.grey[600],
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}