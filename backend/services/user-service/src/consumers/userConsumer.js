import { KafkaConsumer, TOPICS } from '../../../../shared/index.js';
import Patient from '../models/Patient.js';
import Doctor from '../models/Doctor.js';

/**
 * Initialize Kafka consumer for user service
 */
export const initializeConsumer = async () => {
  const consumer = new KafkaConsumer(
    process.env.KAFKA_GROUP_ID || 'user-service-group'
  );

  await consumer.connect();
  await consumer.subscribe([TOPICS.AUTH.USER_REGISTERED]);

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
      }

    } catch (error) {
      console.error('❌ Error handling user registration event:', error);
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
