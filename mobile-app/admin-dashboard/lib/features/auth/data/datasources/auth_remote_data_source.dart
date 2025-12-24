import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('User not found');
      }

      // Get additional user information from Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw AuthException('User data not found');
      }

      // Ensure this is an admin
      final userData = userDoc.data()!;

      if (userData['role'] != UserEntity.ROLE_ADMIN) {
        await firebaseAuth.signOut();
        throw UnauthorizedException();
      }

      // Update the last login time
      await firestore.collection('users').doc(user.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
        'isOnline': true,
      });

      return UserModel(
        id: user.uid,
        name: userData['name'] ?? 'Admin User',
        email: user.email!,
        phoneNumber: userData['phoneNumber'],
        role: userData['role'] ?? UserEntity.ROLE_ADMIN,
        isOnline: true,
        lastLogin: DateTime.now(),
        createdAt:
            userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt'])
                : DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('No user found for that email');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Wrong password provided');
      } else {
        throw AuthException(e.message ?? 'Authentication error');
      }
    } catch (e) {
      if (e is AuthException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
        });
      }
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data()!;

      // Check if this is an admin
      if (userData['role'] != UserEntity.ROLE_ADMIN) {
        return null;
      }

      return UserModel(
        id: user.uid,
        name: userData['name'] ?? 'Admin User',
        email: user.email!,
        phoneNumber: userData['phoneNumber'],
        role: userData['role'] ?? UserEntity.ROLE_ADMIN,
        isOnline: userData['isOnline'] ?? false,
        lastLogin:
            userData['lastLogin'] != null
                ? DateTime.parse(userData['lastLogin'])
                : null,
        createdAt:
            userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt'])
                : null,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;

      // Check if this is an admin
      return userData['role'] == UserEntity.ROLE_ADMIN;
    } catch (e) {
      return false;
    }
  }
}
