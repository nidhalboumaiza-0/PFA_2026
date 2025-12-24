import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../constants/routes.dart';

class AuthGuard {
  static bool canActivate(BuildContext context, List<String> allowedRoles) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return false;
    }

    final currentUserRole = authState.user.role;
    return allowedRoles.contains(currentUserRole);
  }

  static void redirectToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  static void redirectToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  // Define common role-based permissions
  static const List<String> adminOnlyRoles = [UserEntity.ROLE_ADMIN];
  static const List<String> adminAndMedecinRoles = [
    UserEntity.ROLE_ADMIN,
    UserEntity.ROLE_MEDECIN,
  ];
  static const List<String> allRoles = [
    UserEntity.ROLE_ADMIN,
    UserEntity.ROLE_MEDECIN,
    UserEntity.ROLE_PATIENT,
  ];
}
