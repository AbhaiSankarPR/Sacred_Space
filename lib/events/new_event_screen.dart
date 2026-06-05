import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sacred_space/auth/auth_service.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _slotsController = TextEditingController(text: "100");
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  bool _isLoading = false;

  void _submitEvent() async {
    final loc = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedStartTime != null) {
      setState(() => _isLoading = true);

      final fullDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );

      try {
        final success = await _authService.createEvent({
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "location": _locController.text.trim(),
          "date": fullDate.toUtc().toIso8601String(),
          "maxSlots": int.tryParse(_slotsController.text.trim()) ?? 100,
        });

        if (success) {
          if (mounted) _showSuccessDialog(loc);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to create event. Please try again.")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (_selectedDate == null || _selectedStartTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date and time")),
        );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              loc.newEvent,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Event created and members notified successfully.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Pop back to Events Screen with success flag
                },
                child: Text(
                  loc.ok,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
        title: Text(loc.newEvent),
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
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "e.g. Choir Practice, Youth Meeting",
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 20),

              _buildSectionLabel("Location", theme),
              TextFormField(
                controller: _locController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "e.g. Parish Hall, Church Grounds",
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 20),

              _buildSectionLabel("Max Slots", theme),
              TextFormField(
                controller: _slotsController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g. 50, 100",
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return loc.fieldRequired;
                  if (int.tryParse(val.trim()) == null) return "Please enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              _buildSectionLabel("Select Time", theme),
              _buildPickerTile(
                theme: theme,
                label: "Select Time",
                value: _selectedStartTime?.format(context),
                icon: Icons.access_time_rounded,
                isFullWidth: true,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) setState(() => _selectedStartTime = t);
                },
              ),
              const SizedBox(height: 20),

              _buildSectionLabel(loc.message, theme),
              TextFormField(
                controller: _descController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: loc.describeEvent,
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
                validator: (val) => (val == null || val.trim().isEmpty) ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "CREATE EVENT",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: theme.textTheme.titleMedium?.color,
        ),
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
            color: hasValue
                ? const Color(0xFF5D3A99).withOpacity(0.3)
                : Colors.transparent,
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
