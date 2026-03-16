class EventData {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final int maxSlots;
   int currentAttendees;
  bool isRegistered;

  EventData({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.maxSlots,
    required this.currentAttendees,
    this.isRegistered = false,
  });

  // Logic to calculate remaining slots
  int get remainingSlots => maxSlots - currentAttendees;

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      // Ensure date is parsed to Local time for accurate display
      startTime: DateTime.parse(json['date']).toLocal(),
      maxSlots: json['maxSlots'] ?? 0,
      // Check direct field first, then nested _count object
      currentAttendees: json['currentAttendees'] ?? 
                       (json['_count'] != null ? json['_count']['registrations'] : 0),
      isRegistered: json['isRegistered'] ?? false,
    );
  }
}