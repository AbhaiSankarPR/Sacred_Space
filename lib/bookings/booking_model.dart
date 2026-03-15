enum BookingStatus { pending, approved, rejected }

class BookingData {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String? requestedBy;
  final String? rejectionReason; // Add this

  BookingData({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.requestedBy,
    this.rejectionReason,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      requestedBy: json['userId'], // You can map this to a name if the API provides it
      status: _parseStatus(json['status']),
      rejectionReason: json['rejectionReason'], // Map from JSON
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED': return BookingStatus.approved;
      case 'REJECTED': return BookingStatus.rejected;
      default: return BookingStatus.pending;
    }
  }
}