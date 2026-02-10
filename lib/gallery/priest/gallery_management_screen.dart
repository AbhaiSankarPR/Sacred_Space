import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';

class GalleryManagementScreen extends StatelessWidget {
  const GalleryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
if (user?.role.toLowerCase() != 'priest') {
  return const Scaffold(body: Center(child: Text("Access Denied")));
}
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery Management"),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D3A99),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Trigger image picker logic
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload New Photo"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12, // Replace with actual gallery data
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => print("Delete image $index"),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}