import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/services/api_service.dart';
import 'package:medical_app/features/specialties/data/models/specialty_model.dart';

class SpecialtyApiDataSource {
  Future<List<SpecialtyModel>> getAllSpecialties() async {
    try {
      final response = await ApiService.getRequest(
        AppConstants.specialitiesEndpoint,
      );

      final specialtiesList =
          (response['data'] as List)
              .map((specialty) => SpecialtyModel.fromJson(specialty))
              .toList();

      return specialtiesList;
    } catch (e) {
      throw ServerException(message: 'Error fetching specialties: $e');
    }
  }

  Future<SpecialtyModel> getSpecialtyById(String id) async {
    try {
      final response = await ApiService.getRequest(
        '${AppConstants.specialitiesEndpoint}/$id',
      );
      return SpecialtyModel.fromJson(response['data']);
    } catch (e) {
      throw ServerException(message: 'Error fetching specialty: $e');
    }
  }
}
