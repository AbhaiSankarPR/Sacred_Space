import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'booking_model.dart';
import 'booking_service.dart';

class ParishCalendarScreen extends StatefulWidget {
  const ParishCalendarScreen({super.key});

  @override
  State<ParishCalendarScreen> createState() => _ParishCalendarScreenState();
}

class _ParishCalendarScreenState extends State<ParishCalendarScreen> {
  final BookingService _service = BookingService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<BookingData>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents(_focusedDay);
  }

  Color _getEventColor(String title) {
    switch (title.toLowerCase()) {
      case 'marriage':
      case 'wedding':
        return const Color(0xFFE91E63);
      case 'baptism':
        return const Color(0xFF03A9F4);
      case 'prayer':
      case 'community prayer meeting':
        return const Color(0xFFFF9800);
      case 'choir practice':
        return const Color(0xFF9C27B0);
      case 'funeral':
        return Colors.blueGrey;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Future<void> _loadEvents(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final events = await _service.fetchCalendarEvents(date.month, date.year);
      
      Map<DateTime, List<BookingData>> grouped = {};
      for (var event in events) {
        final dateKey = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        if (grouped[dateKey] == null) grouped[dateKey] = [];
        grouped[dateKey]!.add(event);
      }

      setState(() {
        _events = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<BookingData> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selectedEvents = _getEventsForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text(loc.parishCalendar ?? "Parish Calendar"),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadEvents(_focusedDay);
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(theme),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99)))
              : _buildEventSection(selectedEvents, loc, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        rowHeight: 52,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadEvents(focusedDay);
        },
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          weekendStyle: const TextStyle(color: Color(0xFFE91E63)),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
          weekendTextStyle: const TextStyle(color: Color(0xFFE91E63)),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF5D3A99).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Color(0xFF5D3A99), fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF5D3A99),
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((event) {
                final booking = event as BookingData;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getEventColor(booking.title),
                  ),
                );
              }).toList(),
            );
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18, 
            color: theme.textTheme.titleLarge?.color
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
          rightChevronIcon: Icon(Icons.chevron_right, color: theme.iconTheme.color),
        ),
      ),
    );
  }

  Widget _buildEventSection(List<BookingData> events, AppLocalizations loc, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay!),
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? Colors.grey, 
              fontSize: 14
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState(loc)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _buildEventTile(events[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEventTile(BookingData event) {
    final Color categoryColor = _getEventColor(event.title);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailsSheet(event, loc, theme),
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                color: theme.textTheme.titleMedium?.color
                              ),
                            ),
                            Text(
                              DateFormat.jm().format(event.startTime.toLocal()),
                              style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), 
                            fontSize: 13, 
                            height: 1.4
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(BookingData data, AppLocalizations loc, ThemeData theme) {
    final Color categoryColor = _getEventColor(data.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.church_rounded, color: categoryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 20,
                      color: theme.textTheme.titleLarge?.color
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 32, color: theme.dividerColor),
            _buildPopupDetailRow(Icons.calendar_today_rounded, loc.selectDate, DateFormat.yMMMMd().format(data.startTime), theme),
            _buildPopupDetailRow(Icons.access_time_filled_rounded, loc.startTime, 
                "${DateFormat.jm().format(data.startTime.toLocal())} - ${DateFormat.jm().format(data.endTime.toLocal())}", theme),
            const SizedBox(height: 20),
            Text(
              loc.purposeNotes,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14, 
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color, 
                fontSize: 15, 
                height: 1.5
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(loc.ok.toUpperCase(), style:   TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupDetailRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
            Icon(icon, size: 18, color: Color(0xFF5D3A99)),
          const SizedBox(width: 12),
          Text(
            "$label: ", 
            style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 14)
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color
              )
            )
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            loc.noBookingsFound, 
            style:   TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    ); 
  }
}