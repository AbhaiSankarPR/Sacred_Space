import '../auth/api_service.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  /// Post a new user rating and review
  Future<String> postRating(int rating, String review) async {
    try {
      final response = await apiService.post('/user/ratings', {
        'rating': rating,
        'review': review.trim(),
      });
      
      return response.data['message'] ?? "Thank you for your rating";
    } catch (e) {
      rethrow;
    }
  }
}