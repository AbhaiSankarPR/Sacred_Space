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
  final TextEditingController _customTypeController = TextEditingController();
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

      final String finalTitle = (_selectedType == "Other") 
          ? _customTypeController.text.trim() 
          : (_selectedType ?? "");

      final start = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedStartTime!.hour, _selectedStartTime!.minute,
      );

      final end = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedEndTime!.hour, _selectedEndTime!.minute,
      );

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorOccurred)), 
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        await _service.createBooking({
          "title": finalTitle,
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(loc.requestSent,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.titleLarge?.color)),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              _buildSectionLabel(loc.eventType, theme),
              DropdownButtonFormField<String>(
                dropdownColor: theme.cardColor,
                value: _selectedType,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                hint: Text(loc.selectEventType ?? "Select Event Type", style: TextStyle(color: theme.hintColor)),
                items: [
                  DropdownMenuItem(value: "Marriage", child: Text(loc.marriageCeremony)),
                  DropdownMenuItem(value: "Baptism", child: Text(loc.baptism)),
                  DropdownMenuItem(value: "Prayer", child: Text(loc.prayerMeeting)),
                  DropdownMenuItem(value: "Other", child: Text(loc.other ?? "Other")),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                validator: (val) => val == null ? loc.fieldRequired : null,
              ),
              
              if (_selectedType == "Other") ...[
                const SizedBox(height: 16),
                _buildSectionLabel(loc.customEventName ?? "Event Name", theme),
                TextFormField(
                  controller: _customTypeController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: loc.enterEventName ?? "e.g. Anniversary, House Blessing",
                    hintStyle: TextStyle(color: theme.hintColor),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => (_selectedType == "Other" && (val == null || val.isEmpty)) 
                      ? loc.fieldRequired : null,
                ),
              ],
              
              const SizedBox(height: 24),

              _buildSectionLabel(loc.selectDate, theme),
              _buildPickerTile(
                theme: theme,
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
                        _buildSectionLabel(loc.startTime, theme),
                        _buildPickerTile(
                          theme: theme,
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
                        _buildSectionLabel(loc.endTime, theme),
                        _buildPickerTile(
                          theme: theme,
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

              _buildSectionLabel(loc.purposeNotes, theme),
              TextFormField(
                controller: _noteController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: loc.describeEvent,
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
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

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.titleMedium?.color),
      ),
    );
  }

  Widget _buildPickerTile({
    required ThemeData theme,
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    final bool hasValue = value != null;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
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
                  color: hasValue 
                      ? theme.textTheme.bodyLarge?.color 
                      : theme.hintColor,
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