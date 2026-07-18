import '../auth/api_service.dart'; 

class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  Future<String> submitComplaint({required String title, required String description}) async {
    try {
      final response = await apiService.post('/user/app-complaints', {
        'title': title.trim(),
        'description': description.trim(),
      });
      
      return response.data['message'] ?? "Feedback sent successfully";
    } catch (e) {
      rethrow; 
    }
  }
}