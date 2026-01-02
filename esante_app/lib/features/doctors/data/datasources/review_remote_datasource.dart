import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/review_model.dart';

/// Data source for doctor reviews
abstract class ReviewRemoteDataSource {
  /// Submit a review for a completed appointment
  /// POST /api/v1/reviews/appointments/:appointmentId
  Future<ReviewModel> submitReview({
    required String appointmentId,
    required int rating,
    String? comment,
  });

  /// Get all reviews for a doctor
  /// GET /api/v1/reviews/doctors/:doctorId
  Future<ReviewsResponse> getDoctorReviews({
    required String doctorId,
    int page = 1,
    int limit = 10,
  });

  /// Get review for a specific appointment
  /// GET /api/v1/reviews/appointments/:appointmentId
  Future<ReviewModel?> getAppointmentReview({
    required String appointmentId,
  });

  /// Update a review (within 24 hours)
  /// PUT /api/v1/reviews/:reviewId
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  });

  /// Delete a review (within 24 hours)
  /// DELETE /api/v1/reviews/:reviewId
  Future<void> deleteReview({
    required String reviewId,
  });
}

/// Response wrapper for paginated reviews
class ReviewsResponse {
  final List<ReviewModel> reviews;
  final RatingStatsModel stats;
  final int total;
  final int currentPage;
  final int totalPages;

  ReviewsResponse({
    required this.reviews,
    required this.stats,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient _apiClient;

  ReviewRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[ReviewRemoteDataSource.$method] $message');
  }

  @override
  Future<ReviewModel> submitReview({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    _log('submitReview', 'Submitting review for appointment: $appointmentId');

    final response = await _apiClient.post(
      '${ApiList.reviews}/appointments/$appointmentId',
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );

    _log('submitReview', 'Review submitted successfully');
    return ReviewModel.fromJson(response['data']);
  }

  @override
  Future<ReviewsResponse> getDoctorReviews({
    required String doctorId,
    int page = 1,
    int limit = 10,
  }) async {
    _log('getDoctorReviews', 'Getting reviews for doctor: $doctorId');

    final response = await _apiClient.get(
      '${ApiList.reviews}/doctors/$doctorId',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final reviewsList = (data['reviews'] as List?)
            ?.map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
            .toList() ??
        [];

    final stats = data['stats'] != null
        ? RatingStatsModel.fromJson(data['stats'] as Map<String, dynamic>)
        : RatingStatsModel.fromReviews(reviewsList);

    _log('getDoctorReviews', 'Got ${reviewsList.length} reviews');

    return ReviewsResponse(
      reviews: reviewsList,
      stats: stats,
      total: data['total'] ?? reviewsList.length,
      currentPage: data['page'] ?? page,
      totalPages: data['totalPages'] ?? 1,
    );
  }

  @override
  Future<ReviewModel?> getAppointmentReview({
    required String appointmentId,
  }) async {
    _log('getAppointmentReview', 'Getting review for appointment: $appointmentId');

    try {
      final response = await _apiClient.get(
        '${ApiList.reviews}/appointments/$appointmentId',
      );

      if (response['data'] != null) {
        _log('getAppointmentReview', 'Found existing review');
        return ReviewModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // 404 means no review exists yet
      _log('getAppointmentReview', 'No existing review found');
      return null;
    }
  }

  @override
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    _log('updateReview', 'Updating review: $reviewId');

    final response = await _apiClient.put(
      '${ApiList.reviews}/$reviewId',
      data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );

    _log('updateReview', 'Review updated successfully');
    return ReviewModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
  }) async {
    _log('deleteReview', 'Deleting review: $reviewId');

    await _apiClient.delete('${ApiList.reviews}/$reviewId');

    _log('deleteReview', 'Review deleted successfully');
  }
}
