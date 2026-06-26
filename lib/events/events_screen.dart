import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../core/routes.dart';
import 'event_model.dart';
import './event_card.dart';
import '../core/models/paginated_response.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = "Upcoming";
  List<EventData> _events = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  final int _limit = 8;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchEvents(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchEvents(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchEvents({
    bool isRefresh = false,
    bool isLoadMore = false,
  }) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    } else if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    }

    try {
      final int pageToFetch = isLoadMore ? _currentPage + 1 : 1;
      PaginatedResponse<EventData> response;

      if (_selectedFilter == "My Events") {
        response = await _authService.getMyRegistrations(
          page: pageToFetch,
          limit: _limit,
        );
      } else {
        response = await _authService.getEvents(
          type: _selectedFilter.toLowerCase(),
          page: pageToFetch,
          limit: _limit,
        );
      }

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _events.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _events = response.data;
            _currentPage = 1;
          }
          _hasMore = response.meta.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent <= 0 &&
              _hasMore &&
              !_isLoading &&
              !_isLoadingMore) {
            _fetchEvents(isLoadMore: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      _showSnackBar("Failed to load events", isError: true);
    }
  }

  Future<void> _handleRSVP(EventData event) async {
    final loc = AppLocalizations.of(context)!;
    bool success = false;

    // 1. If already registered, confirm unregistration first
    if (event.isRegistered) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Cancel Registration?"),
              content: Text("Do you want to unregister from '${event.title}'?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("UNREGISTER"),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Call Unregister API
      setState(() => _isLoading = true);
      success = await _authService.unregisterFromEvent(event.id);

      if (success && mounted) {
        setState(() {
          event.isRegistered = false;
          event.currentAttendees--; // Update local count
          _isLoading = false;
        });
        _showSnackBar("Registration cancelled");
      }
    }
    // 2. If not registered, perform registration
    else {
      // Check if event is full before attempting (safety check)
      if (event.maxSlots - event.currentAttendees <= 0) {
        _showSnackBar("This event is already full", isError: true);
        return;
      }

      setState(() => _isLoading = true);
      success = await _authService.registerForEvent(event.id);

      if (success && mounted) {
        setState(() {
          event.isRegistered = true;
          event.currentAttendees++; // Update local count
          _isLoading = false;
        });
        _showSnackBar(loc.rsvpUpdated);
      }
    }

    if (!success && mounted) {
      setState(() => _isLoading = false);
      _showSnackBar("Action failed. Please try again.", isError: true);
    }
  }

  Future<void> _handleDelete(String eventId) async {
    try {
      await _authService.deleteEvent(eventId);
      setState(() => _events.removeWhere((e) => e.id == eventId));
      _showSnackBar("Event deleted successfully");
    } catch (e) {
      _showSnackBar("Could not delete event", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = _authService.currentUser;
    final bool isPriest = user?.role.toLowerCase() == 'priest';

    final String currentFilterLabel =
        _selectedFilter == "Upcoming"
            ? loc.upcoming
            : (_selectedFilter == "Past" ? loc.past : loc.myEvents);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.eventsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: AppDrawer(user: user!),
      floatingActionButton:
          isPriest
              ? FloatingActionButton(
                backgroundColor: const Color(0xFF5D3A99),
                onPressed: () async {
                  final success = await Navigator.pushNamed(
                    context,
                    Routes.newEvent,
                  );
                  if (success == true) {
                    _fetchEvents();
                  }
                },
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: Column(
        children: [
          _buildFilterTabs(loc, isPriest),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5D3A99),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchEvents,
                      child:
                          _events.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          loc.noEventsFound(
                                            currentFilterLabel.toLowerCase(),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                itemCount:
                                    _events.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (ctx, index) {
                                  if (index == _events.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF5D3A99),
                                        ),
                                      ),
                                    );
                                  }
                                  final event = _events[index];
                                  return EventCard(
                                    event: event,
                                    isPriest: isPriest,
                                    onRSVP: () => _handleRSVP(event),
                                    onDelete: () => _handleDelete(event.id),
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppLocalizations loc, bool isPriest) {
    final theme = Theme.of(context);

    // Dynamically generate the list of tabs
    final List<String> tabs = ["Upcoming", if (!isPriest) "My Events", "Past"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            tabs
                .map(
                  (tab) => _FilterTab(
                    label:
                        tab == "Upcoming"
                            ? loc.upcoming
                            : (tab == "Past" ? loc.past : loc.myEvents),
                    isSelected: _selectedFilter == tab,
                    onTap: () {
                      setState(() => _selectedFilter = tab);
                      _fetchEvents();
                    },
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF5D3A99)
                  : (isDark ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
