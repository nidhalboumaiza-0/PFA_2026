import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import '../models/dossier_medical_model.dart';
import 'package:path/path.dart' as path;

abstract class DossierMedicalRemoteDataSource {
  Future<DossierMedicalModel> getDossierMedical(String patientId);
  Future<DossierMedicalModel> addFileToDossier(
    String patientId,
    File file,
    String description,
  );
  Future<DossierMedicalModel> addFilesToDossier(
    String patientId,
    List<File> files,
    Map<String, String> descriptions,
  );
  Future<Unit> deleteFile(String patientId, String fileId);
  Future<Unit> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  );
  Future<bool> hasDossierMedical(String patientId);
}

class DossierMedicalRemoteDataSourceImpl
    implements DossierMedicalRemoteDataSource {
  final http.Client client;
  final String baseUrl = AppConstants.dossierMedicalEndpoint;

  DossierMedicalRemoteDataSourceImpl({http.Client? client})
    : this.client = client ?? http.Client();

  @override
  Future<DossierMedicalModel> getDossierMedical(String patientId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return DossierMedicalModel.fromJson(jsonResponse['data']['dossier']);
      } else if (response.statusCode == 404) {
        // If dossier not found, return empty dossier
        return DossierMedicalModel.empty(patientId);
      } else {
        throw ServerException(
          message:
              'Failed to get medical dossier. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFileToDossier(
    String patientId,
    File file,
    String description,
  ) async {
    try {
      final fileExtension = path.extension(file.path).replaceAll('.', '');
      final mimeType = _getMimeType(fileExtension);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$patientId/files'),
      );

      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: path.basename(file.path),
          contentType: MediaType(
            mimeType.split('/')[0],
            mimeType.split('/')[1],
          ),
        ),
      );

      if (description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return DossierMedicalModel.fromJson(jsonResponse['data']['dossier']);
      } else {
        throw ServerException(
          message: 'Failed to add file. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFilesToDossier(
    String patientId,
    List<File> files,
    Map<String, String> descriptions,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$patientId/multiple-files'),
      );

      for (var file in files) {
        final fileExtension = path.extension(file.path).replaceAll('.', '');
        final mimeType = _getMimeType(fileExtension);

        request.files.add(
          http.MultipartFile(
            'files',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: path.basename(file.path),
            contentType: MediaType(
              mimeType.split('/')[0],
              mimeType.split('/')[1],
            ),
          ),
        );
      }

      if (descriptions.isNotEmpty) {
        request.fields['descriptions'] = json.encode(descriptions);
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return DossierMedicalModel.fromJson(jsonResponse['data']['dossier']);
      } else {
        throw ServerException(
          message: 'Failed to add files. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<Unit> deleteFile(String patientId, String fileId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/$patientId/files/$fileId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        throw ServerException(
          message: 'Failed to delete file. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<Unit> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  ) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/$patientId/files/$fileId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'description': description}),
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        throw ServerException(
          message:
              'Failed to update file description. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<bool> hasDossierMedical(String patientId) async {
    try {
      final dossier = await getDossierMedical(patientId);
      return dossier.files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
