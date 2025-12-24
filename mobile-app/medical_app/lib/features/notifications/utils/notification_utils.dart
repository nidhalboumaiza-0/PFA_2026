import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationUtils {
  /// Convert a string to NotificationType enum
  static NotificationType stringToNotificationType(String type) {
    switch (type) {
      case 'general':
        return NotificationType.general;
      case 'appointment':
        return NotificationType.appointment;
      case 'prescription':
        return NotificationType.prescription;
      case 'message':
        return NotificationType.message;
      case 'medical_record':
        return NotificationType.medicalRecord;
      case 'newAppointment':
        return NotificationType.newAppointment;
      case 'appointmentAccepted':
        return NotificationType.appointmentAccepted;
      case 'appointmentRejected':
        return NotificationType.appointmentRejected;
      case 'rating':
        return NotificationType.rating;
      case 'newPrescription':
        return NotificationType.newPrescription;
      default:
        return NotificationType.general;
    }
  }

  /// Convert NotificationType enum to string
  static String notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return 'general';
      case NotificationType.appointment:
        return 'appointment';
      case NotificationType.prescription:
        return 'prescription';
      case NotificationType.message:
        return 'message';
      case NotificationType.medicalRecord:
        return 'medical_record';
      case NotificationType.newAppointment:
        return 'newAppointment';
      case NotificationType.appointmentAccepted:
        return 'appointmentAccepted';
      case NotificationType.appointmentRejected:
        return 'appointmentRejected';
      case NotificationType.rating:
        return 'rating';
      case NotificationType.newPrescription:
        return 'newPrescription';
      case NotificationType.appointmentConfirmed:
        return 'appointmentConfirmed';
      case NotificationType.appointmentReminder:
        return 'appointmentReminder';
      case NotificationType.appointmentCancelled:
        return 'appointmentCancelled';
      case NotificationType.newMessage:
        return 'newMessage';
      case NotificationType.referralReceived:
        return 'referralReceived';
      case NotificationType.referralScheduled:
        return 'referralScheduled';
      case NotificationType.consultationCreated:
        return 'consultationCreated';
      case NotificationType.prescriptionCreated:
        return 'prescriptionCreated';
      case NotificationType.documentUploaded:
        return 'documentUploaded';
      case NotificationType.systemAlert:
        return 'systemAlert';
    }
  }

  /// Get notification title based on type
  static String getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return 'Notification';
      case NotificationType.appointment:
        return 'Appointment';
      case NotificationType.prescription:
        return 'Prescription';
      case NotificationType.message:
        return 'New Message';
      case NotificationType.medicalRecord:
        return 'Medical Record';
      case NotificationType.newAppointment:
        return 'New Appointment Request';
      case NotificationType.appointmentAccepted:
        return 'Appointment Accepted';
      case NotificationType.appointmentRejected:
        return 'Appointment Rejected';
      case NotificationType.rating:
        return 'New Rating';
      case NotificationType.newPrescription:
        return 'New Prescription';
      case NotificationType.appointmentConfirmed:
        return 'Appointment Confirmed';
      case NotificationType.appointmentReminder:
        return 'Appointment Reminder';
      case NotificationType.appointmentCancelled:
        return 'Appointment Cancelled';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.referralReceived:
        return 'Referral Received';
      case NotificationType.referralScheduled:
        return 'Referral Scheduled';
      case NotificationType.consultationCreated:
        return 'Consultation Created';
      case NotificationType.prescriptionCreated:
        return 'Prescription Created';
      case NotificationType.documentUploaded:
        return 'Document Uploaded';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }
}
