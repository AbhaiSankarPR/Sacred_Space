class EventData {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String category;
  bool isRegistered;
  final List<String> registeredMembers; // Add this list

  EventData({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.category,
    this.isRegistered = false,
    this.registeredMembers = const [], // Default to empty
  });
}