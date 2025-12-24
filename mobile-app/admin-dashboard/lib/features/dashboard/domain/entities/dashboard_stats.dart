class ActivityStats {
  final DateTime date;
  final int activeUsers;
  final int inactiveUsers;

  const ActivityStats({
    required this.date,
    required this.activeUsers,
    required this.inactiveUsers,
  });
}

class LoginStats {
  final DateTime date;
  final int logins;
  final int logouts;

  const LoginStats({
    required this.date,
    required this.logins,
    required this.logouts,
  });
}

class DashboardStats {
  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final List<ActivityStats> activityStats;
  final List<LoginStats> loginStats;

  const DashboardStats({
    required this.totalUsers,
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.activityStats,
    required this.loginStats,
  });
}
