import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/ratings/data/models/doctor_rating_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class RatingRemoteDataSource {
  /// Submit a rating for a doctor
  Future<void> submitDoctorRating(DoctorRatingModel rating);

  /// Get all ratings for a specific doctor
  Future<List<DoctorRatingModel>> getDoctorRatings(String doctorId);

  /// Get average rating for a doctor
  Future<double> getDoctorAverageRating(String doctorId);

  /// Check if patient has already rated a specific appointment
  Future<bool> hasPatientRatedAppointment(
    String patientId,
    String rendezVousId,
  );
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final http.Client client;

  RatingRemoteDataSourceImpl({required this.client});

  // Helper method to get the auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('TOKEN');
  }

  @override
  Future<void> submitDoctorRating(DoctorRatingModel rating) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.post(
        Uri.parse(AppConstants.ratingsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'doctorId': rating.doctorId,
          'rendezVousId': rating.rendezVousId,
          'rating': rating.rating,
          'comment': rating.comment ?? '',
        }),
      );

      if (response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to submit rating',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<List<DoctorRatingModel>> getDoctorRatings(String doctorId) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.ratingsEndpoint}/doctor/$doctorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to get doctor ratings',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> ratingsData = responseData['data']['ratings'];
      return ratingsData.map((ratingData) {
        return DoctorRatingModel.fromJson({
          'id': ratingData['_id'],
          'doctorId': ratingData['doctorId'],
          'patientId':
              ratingData['patientId'] is Map
                  ? ratingData['patientId']['_id']
                  : ratingData['patientId'],
          'patientName':
              ratingData['patientId'] is Map
                  ? '${ratingData['patientId']['name']} ${ratingData['patientId']['lastName']}'
                  : null,
          'rating': ratingData['rating'].toDouble(),
          'comment': ratingData['comment'],
          'createdAt': ratingData['createdAt'],
          'rendezVousId': ratingData['rendezVousId'],
        });
      }).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<double> getDoctorAverageRating(String doctorId) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.ratingsEndpoint}/doctor/$doctorId/average'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message:
              errorBody['message'] ?? 'Failed to get doctor average rating',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final double averageRating =
          responseData['data']['averageRating']?.toDouble() ?? 0.0;
      return averageRating;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<bool> hasPatientRatedAppointment(
    String patientId,
    String rendezVousId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.get(
        Uri.parse('${AppConstants.ratingsEndpoint}/check-rated/$rendezVousId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message:
              errorBody['message'] ?? 'Failed to check if appointment is rated',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['data']['hasRated'] as bool;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
