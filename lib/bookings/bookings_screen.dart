import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../auth/auth_service.dart';

class BookingsScreen extends StatelessWidget {
  final User user;

  const BookingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Bookings",
      user: user, // pass user to scaffold
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          BookingCard(
            title: "Marriage Ceremony",
            date: "12 Feb 2026",
            status: "Approved",
            color: Colors.green,
          ),
          BookingCard(
            title: "Prayer Hall",
            date: "20 Feb 2026",
            status: "Pending",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final Color color;

  const BookingCard({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(date),
        trailing: Chip(
          label: Text(status),
          backgroundColor: color.withOpacity(0.15),
          labelStyle: TextStyle(color: color),
        ),
      ),
    );
  }
}
