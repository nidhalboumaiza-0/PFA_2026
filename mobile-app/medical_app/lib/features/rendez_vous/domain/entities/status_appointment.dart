enum StatusAppointment {
  pending,
  accepted,
  rejected,
  completed
}

// Extension to convert enum to string
extension StatusAppointmentExtension on StatusAppointment {
  String toShortString() {
    return toString().split('.').last;
  }
  
  // Convert from string to enum
  static StatusAppointment fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusAppointment.pending;
      case 'accepted':
        return StatusAppointment.accepted;
      case 'rejected':
        return StatusAppointment.rejected;
      case 'completed':
        return StatusAppointment.completed;
      default:
        return StatusAppointment.pending;
    }
  }
} 