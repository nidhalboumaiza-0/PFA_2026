import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/constants.dart';
import 'auth_local_data_source.dart';

// DEPRECATED: Kept for backward compatibility only
// Backend uses token-based verification, not codes
enum VerificationCodeType {
  activationDeCompte,
  motDePasseOublie,
  changerMotDePasse,
  compteActive,
}

abstract class AuthRemoteDataSource {
  Future<void> signInWithGoogle();
  Future<Unit> createAccount(UserModel user, String password);
  Future<UserModel> login(String email, String password);
  Future<Unit> logout();
  Future<Unit> verifyEmailWithToken(String token);
  Future<Unit> resendVerification(String email);
  Future<Unit> forgotPassword(String email);
  Future<Unit> resetPasswordWithToken(String token, String newPassword);
  Future<Unit> changePassword(String currentPassword, String newPassword);
  Future<String> refreshToken(String refreshToken);
  Future<Unit> updateUser(UserModel user);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthLocalDataSource localDataSource;
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.localDataSource, required this.client});

  // Helper: Map gender from backend (male/female/other) to app (Homme/Femme/Autre)
  String _mapGenderFromBackend(String? backendGender) {
    if (backendGender == null) return 'Homme';
    switch (backendGender.toLowerCase()) {
      case 'male':
        return 'Homme';
      case 'female':
        return 'Femme';
      case 'other':
        return 'Autre';
      default:
        return 'Homme';
    }
  }

  // Helper: Map gender from app (Homme/Femme/Autre) to backend (male/female/other)
  String _mapGenderToBackend(String appGender) {
    switch (appGender) {
      case 'Homme':
        return 'male';
      case 'Femme':
        return 'female';
      case 'Autre':
        return 'other';
      default:
        return 'male';
    }
  }

  // Helper method to handle HTTP errors
  void _handleHttpError(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'Unknown error';
      
      if (response.statusCode == 401) {
        throw UnauthorizedException(message);
      } else if (response.statusCode == 403) {
        throw AuthException(message: message);
      } else if (response.statusCode == 404) {
        throw AuthException(message: message);
      } else if (response.statusCode == 400) {
        throw AuthException(message: message);
      } else if (response.statusCode == 409) {
        throw AuthException(message: message);
      } else {
        throw ServerException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Server error: ${response.statusCode}');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    throw UnimplementedError('Google Sign In not yet implemented');
  }

  @override
  Future<Unit> createAccount(UserModel user, String password) async {
    try {
      final Map<String, dynamic> profileData = {};
      
      if (user is PatientModel) {
        profileData['firstName'] = user.name;
        profileData['lastName'] = user.lastName;
        profileData['gender'] = _mapGenderToBackend(user.gender);
        profileData['phone'] = user.phoneNumber;
        if (user.dateOfBirth != null) {
          profileData['dateOfBirth'] = user.dateOfBirth!.toIso8601String();
        }
        if (user.antecedent != null && user.antecedent!.isNotEmpty) {
          profileData['chronicDiseases'] = [user.antecedent];
        }
        if (user.bloodType?.isNotEmpty == true) {
          profileData['bloodType'] = user.bloodType;
        }
        if (user.allergies?.isNotEmpty == true) {
          profileData['allergies'] = user.allergies;
        }
      } else if (user is MedecinModel) {
        profileData['firstName'] = user.name;
        profileData['lastName'] = user.lastName;
        profileData['gender'] = _mapGenderToBackend(user.gender);
        profileData['phone'] = user.phoneNumber;
        profileData['specialty'] = user.speciality;
        profileData['licenseNumber'] = user.numLicence;
        if (user.dateOfBirth != null) {
          profileData['dateOfBirth'] = user.dateOfBirth!.toIso8601String();
        }
        if (user.consultationFee != null && user.consultationFee! > 0) {
          profileData['consultationFee'] = user.consultationFee;
        }
      }

      final response = await client.post(
        Uri.parse(AppConstants.signupEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email.toLowerCase().trim(),
          'password': password,
          'role': user.role == 'medecin' ? 'doctor' : user.role,
          'profileData': profileData,
        }),
      );

      if (response.statusCode == 201) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Registration failed');
      }
    } catch (e) {
      if (e is AuthException || e is UnauthorizedException) rethrow;
      throw ServerException(message: 'Registration error: $e');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse(AppConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        await localDataSource.saveToken(token);
        await localDataSource.saveRefreshToken(refreshToken);

        // Fetch profile
        final profileResponse = await client.get(
          Uri.parse(AppConstants.getUserProfileEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final userObj = profileData['user'];
          final profileObj = profileData['profile'];

          final Map<String, dynamic> mergedData = {
            'id': userObj['id'],
            'email': userObj['email'],
            'role': userObj['role'] == 'doctor' ? 'medecin' : userObj['role'],
            'name': profileObj['firstName'] ?? '',
            'lastName': profileObj['lastName'] ?? '',
            'gender': _mapGenderFromBackend(profileObj['gender']),
            'phoneNumber': profileObj['phone'] ?? '',
            'dateOfBirth': profileObj['dateOfBirth'],
            'profilePicture': profileObj['profilePhoto'],
            'accountStatus': userObj['isActive'] ?? true,
          };

          if (userObj['role'] == 'doctor') {
            mergedData['speciality'] = profileObj['specialty'] ?? '';
            mergedData['numLicence'] = profileObj['licenseNumber'] ?? '';
            mergedData['appointmentDuration'] = profileObj['appointmentDuration'] ?? 30;
            mergedData['averageRating'] = (profileObj['rating'] ?? 0.0).toDouble();
            mergedData['totalRatings'] = profileObj['totalReviews'] ?? 0;
            mergedData['consultationFee'] = (profileObj['consultationFee'] ?? 0.0).toDouble();
            
            if (profileObj['clinicAddress']?['coordinates']?['coordinates'] != null) {
              final coords = profileObj['clinicAddress']['coordinates']['coordinates'];
              if (coords is List && coords.length >= 2) {
                mergedData['lng'] = coords[0].toDouble();
                mergedData['lat'] = coords[1].toDouble();
              }
            }
          } else {
            mergedData['antecedent'] = (profileObj['chronicDiseases'] as List?)?.join(', ') ?? '';
            mergedData['bloodType'] = profileObj['bloodType'];
            mergedData['allergies'] = profileObj['allergies'] ?? [];
            mergedData['chronicDiseases'] = profileObj['chronicDiseases'] ?? [];
          }

          final UserModel user = mergedData['role'] == 'patient'
              ? PatientModel.fromJson(mergedData)
              : MedecinModel.fromJson(mergedData);

          await localDataSource.cacheUser(user);
          return user;
        } else {
          throw ServerException(message: 'Failed to fetch profile');
        }
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Login failed');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is AuthException) rethrow;
      throw ServerException(message: 'Login error: $e');
    }
  }

  @override
  Future<Unit> logout() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        try {
          await client.post(
            Uri.parse(AppConstants.logoutEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Continue even if server call fails
        }
      }
      
      await localDataSource.clearToken();
      await localDataSource.clearRefreshToken();
      await localDataSource.clearCachedUser();
      return unit;
    } catch (e) {
      await localDataSource.clearToken();
      await localDataSource.clearRefreshToken();
      await localDataSource.clearCachedUser();
      return unit;
    }
  }

  @override
  Future<Unit> verifyEmailWithToken(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.verifyEmailEndpoint}/$token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Email verification failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Verification error: $e');
    }
  }

  @override
  Future<Unit> resendVerification(String email) async {
    try {
      final response = await client.post(
        Uri.parse(AppConstants.resendVerificationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to resend verification');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Resend error: $e');
    }
  }

  @override
  Future<Unit> forgotPassword(String email) async {
    try {
      final response = await client.post(
        Uri.parse(AppConstants.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to send reset email');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Forgot password error: $e');
    }
  }

  @override
  Future<Unit> resetPasswordWithToken(String token, String newPassword) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.resetPasswordEndpoint}/$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Password reset failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Reset error: $e');
    }
  }

  @override
  Future<Unit> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        throw AuthException(message: 'Not authenticated');
      }

      final response = await client.post(
        Uri.parse(AppConstants.changePasswordEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Password change failed');
      }
    } catch (e) {
      if (e is AuthException || e is UnauthorizedException) rethrow;
      throw ServerException(message: 'Change password error: $e');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await client.post(
        Uri.parse(AppConstants.refreshTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];
        await localDataSource.saveToken(newToken);
        return newToken;
      } else {
        throw UnauthorizedException('Token refresh failed');
      }
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      throw ServerException(message: 'Refresh error: $e');
    }
  }

  @override
  Future<Unit> updateUser(UserModel user) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        throw AuthException(message: 'Not authenticated');
      }

      Map<String, dynamic> updateData = {
        'firstName': user.name,
        'lastName': user.lastName,
        'gender': _mapGenderToBackend(user.gender),
        'phone': user.phoneNumber,
      };

      if (user.dateOfBirth != null) {
        updateData['dateOfBirth'] = user.dateOfBirth!.toIso8601String();
      }

      if (user is MedecinModel) {
        updateData['specialty'] = user.speciality;
        updateData['licenseNumber'] = user.numLicence;
        if (user.consultationFee != null) {
          updateData['consultationFee'] = user.consultationFee;
        }
      } else if (user is PatientModel) {
        if (user.antecedent != null && user.antecedent!.isNotEmpty) {
          updateData['chronicDiseases'] = [user.antecedent];
        }
        if (user.bloodType?.isNotEmpty == true) {
          updateData['bloodType'] = user.bloodType;
        }
        if (user.allergies?.isNotEmpty == true) {
          updateData['allergies'] = user.allergies;
        }
      }

      final response = await client.put(
        Uri.parse(AppConstants.updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await localDataSource.cacheUser(user);
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to update user');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is AuthException) rethrow;
      throw ServerException(message: 'Update error: $e');
    }
  }
}