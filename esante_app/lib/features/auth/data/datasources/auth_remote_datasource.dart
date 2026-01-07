import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/session_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> register({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  });

  Future<(UserModel, AuthTokensModel)> login({
    required String email,
    required String password,
  });

  Future<void> logout({required String sessionId});

  Future<int> logoutAllDevices();

  Future<String> refreshToken({required String refreshToken});

  Future<UserModel> getCurrentUser();

  Future<void> verifyEmail({required String token});

  Future<void> resendVerification({required String email});

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<List<SessionModel>> getActiveSessions();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[AuthRemoteDataSource.$method] $message');
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  }) async {
    _log('register', 'Starting registration for email: $email, role: $role');
    try {
      final response = await _apiClient.post(
        ApiList.authRegister,
        data: {
          'email': email,
          'password': password,
          'role': role,
          if (profileData != null) 'profileData': profileData,
        },
      );
      _log('register', 'Response: $response');
      return response['message'] ?? 'Registration successful';
    } catch (e) {
      _log('register', 'Error: $e');
      rethrow;
    }
  }

  @override
  Future<(UserModel, AuthTokensModel)> login({
    required String email,
    required String password,
  }) async {
    _log('login', 'Starting login for email: $email');
    try {
      final response = await _apiClient.post(
        ApiList.authLogin,
        data: {'email': email, 'password': password},
      );
      _log('login', 'Response received: ${response.keys}');

      // Backend wraps response in { success, message, data: {...} }
      // Extract the data object which contains user, accessToken, refreshToken, sessionId
      final data = response['data'] as Map<String, dynamic>? ?? response;
      _log('login', 'Parsing user from: ${data['user']}');
      final user = UserModel.fromJson(data['user']);
      _log('login', 'User parsed: ${user.email}, role: ${user.role}');
      
      _log('login', 'Parsing tokens...');
      final tokens = AuthTokensModel.fromJson(data);
      _log('login', 'Tokens parsed, sessionId: ${tokens.sessionId}');

      return (user, tokens);
    } catch (e, stackTrace) {
      _log('login', 'Error: $e');
      _log('login', 'StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> logout({required String sessionId}) async {
    await _apiClient.post(
      ApiList.authLogout,
      data: {'sessionId': sessionId},
    );
  }

  @override
  Future<int> logoutAllDevices() async {
    final response = await _apiClient.post(ApiList.authLogoutAll);
    // Extract count from message like "Successfully logged out from all 3 device(s)."
    final message = response['message'] ?? '';
    final match = RegExp(r'(\d+)').firstMatch(message);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  @override
  Future<String> refreshToken({required String refreshToken}) async {
    final response = await _apiClient.post(
      ApiList.authRefreshToken,
      data: {'refreshToken': refreshToken},
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['accessToken'];
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiList.authMe);
    final data = response['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user']);
  }

  @override
  Future<void> verifyEmail({required String token}) async {
    await _apiClient.get(ApiList.authVerifyEmail(token));
  }

  @override
  Future<void> resendVerification({required String email}) async {
    await _apiClient.post(
      ApiList.authResendVerification,
      data: {'email': email},
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post(
      ApiList.authForgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiList.authResetPassword(token),
      data: {'newPassword': newPassword},
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiList.authChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<List<SessionModel>> getActiveSessions() async {
    final response = await _apiClient.get(ApiList.authSessions);
    final data = response['data'] as Map<String, dynamic>;
    final sessions = data['sessions'] as List<dynamic>;
    return sessions.map((s) => SessionModel.fromJson(s)).toList();
  }
}
