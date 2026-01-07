import { KafkaConsumer, TOPICS } from '../../../../shared/index.js';
import Patient from '../models/Patient.js';
import Doctor from '../models/Doctor.js';
import { emitNewUserRegistration } from '../socket/index.js';

/**
 * Initialize Kafka consumer for user service
 */
export const initializeConsumer = async () => {
  const consumer = new KafkaConsumer(
    process.env.KAFKA_GROUP_ID || 'user-service-group'
  );

  await consumer.connect();
  await consumer.subscribe([
    TOPICS.AUTH.USER_REGISTERED,
    TOPICS.RDV.DOCTOR_RATING_UPDATED // Subscribe to rating update events
  ]);

  // Handle user registration events
  consumer.registerHandler(TOPICS.AUTH.USER_REGISTERED, async (message) => {
    try {
      const { userId, email, role, profileData } = message;

      console.log(`📥 Received user registration event: ${userId} (${role})`);

      // Create profile based on role
      if (role === 'patient') {
        const existingPatient = await Patient.findOne({ userId });
        if (existingPatient) {
          console.log(`⚠️ Patient profile already exists for user ${userId}`);
          return;
        }

        const patientData = {
          userId,
          firstName: profileData?.firstName || '',
          lastName: profileData?.lastName || '',
          dateOfBirth: profileData?.dateOfBirth || new Date('2000-01-01'),
          gender: profileData?.gender || 'other',
          phone: profileData?.phone || '',
          ...profileData
        };

        const patient = await Patient.create(patientData);
        console.log(`✅ Created patient profile: ${patient._id}`);

        // Emit real-time event to admin dashboard
        emitNewUserRegistration({
          profileId: patient._id,
          userId,
          email,
          userType: 'patient',
          firstName: patient.firstName,
          lastName: patient.lastName,
          createdAt: patient.createdAt
        });

      } else if (role === 'doctor') {
        const existingDoctor = await Doctor.findOne({ userId });
        if (existingDoctor) {
          console.log(`⚠️ Doctor profile already exists for user ${userId}`);
          return;
        }

        const doctorData = {
          userId,
          firstName: profileData?.firstName || '',
          lastName: profileData?.lastName || '',
          specialty: profileData?.specialty || 'General Practice',
          phone: profileData?.phone || '',
          licenseNumber: profileData?.licenseNumber || `LIC-${Date.now()}`,
          clinicAddress: {
            city: profileData?.city || 'Unknown',
            country: profileData?.country || 'Unknown',
            coordinates: {
              type: 'Point',
              coordinates: [0, 0] // Default coordinates
            }
          },
          ...profileData
        };

        const doctor = await Doctor.create(doctorData);
        console.log(`✅ Created doctor profile: ${doctor._id}`);

        // Emit real-time event to admin dashboard
        emitNewUserRegistration({
          profileId: doctor._id,
          userId,
          email,
          userType: 'doctor',
          firstName: doctor.firstName,
          lastName: doctor.lastName,
          specialty: doctor.specialty,
          isVerified: false,
          createdAt: doctor.createdAt
        });
      }

    } catch (error) {
      console.error('❌ Error handling user registration event:', error);
      throw error; // Will be sent to DLQ
    }
  });

  // Handle doctor rating updated events
  consumer.registerHandler(TOPICS.RDV.DOCTOR_RATING_UPDATED, async (message) => {
    try {
      const { doctorId, rating, totalReviews } = message;

      console.log(`📥 Received doctor rating update: ${doctorId} - ${rating} stars (${totalReviews} reviews)`);

      const doctor = await Doctor.findById(doctorId);
      if (!doctor) {
        console.log(`⚠️ Doctor not found: ${doctorId}`);
        return;
      }

      // Update doctor's rating
      doctor.rating = rating;
      doctor.totalReviews = totalReviews;
      await doctor.save();

      console.log(`✅ Updated doctor ${doctorId} rating to ${rating} (${totalReviews} reviews)`);

    } catch (error) {
      console.error('❌ Error handling doctor rating update:', error);
      throw error; // Will be sent to DLQ
    }
  });

  // Start consuming messages
  await consumer.consume();
  
  console.log('✅ Kafka consumer initialized and listening for events');

  return consumer;
};

export default {
  initializeConsumer
};
