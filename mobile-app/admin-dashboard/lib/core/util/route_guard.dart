import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // If not authenticated, redirect to login
        if (state is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;

        // Check if user has required role
        final bool hasAccess = allowedRoles.contains(user.role);

        if (!hasAccess) {
          // User doesn't have permission, show access denied
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You do not have permission to access this page.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // User has permission, show the protected route
        return child;
      },
    );
  }
}
