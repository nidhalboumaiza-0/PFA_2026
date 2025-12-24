import Prescription from '../models/Prescription.js';
import { kafkaProducer, TOPICS, createEvent } from '../../../../shared/index.js';

/**
 * Auto-lock prescriptions that have exceeded their 1-hour edit window
 * Should be run periodically (e.g., every 5 minutes)
 */
export const autoLockPrescriptions = async () => {
  try {
    console.log('🔒 Running auto-lock job for prescriptions...');

    // Find prescriptions that need locking
    const prescriptionsToLock = await Prescription.find({
      isLocked: false,
      canEditUntil: { $lte: new Date() }
    });

    if (prescriptionsToLock.length === 0) {
      console.log('✅ No prescriptions to lock');
      return {
        success: true,
        lockedCount: 0
      };
    }

    let lockedCount = 0;

    // Lock each prescription
    for (const prescription of prescriptionsToLock) {
      try {
        prescription.isLocked = true;
        prescription.modificationHistory.push({
          modifiedAt: new Date(),
          changeType: 'auto_locked',
          changes: { isLocked: true }
        });

        await prescription.save();

        // Publish Kafka event
        await kafkaProducer.sendEvent(
          TOPICS.MEDICAL.PRESCRIPTION_LOCKED,
          createEvent('prescription.auto_locked', {
            prescriptionId: prescription._id.toString(),
            lockType: 'auto',
            lockedAt: new Date()
          })
        );

        lockedCount++;
      } catch (error) {
        console.error(`❌ Error locking prescription ${prescription._id}:`, error.message);
      }
    }

    console.log(`✅ Auto-locked ${lockedCount} prescription(s)`);

    return {
      success: true,
      lockedCount
    };
  } catch (error) {
    console.error('❌ Auto-lock job failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Start the auto-lock job scheduler
 * Runs every 5 minutes
 */
export const startAutoLockScheduler = () => {
  const FIVE_MINUTES = 5 * 60 * 1000;

  // Run immediately on start
  autoLockPrescriptions();

  // Then run every 5 minutes
  setInterval(() => {
    autoLockPrescriptions();
  }, FIVE_MINUTES);

  console.log('✅ Auto-lock scheduler started (runs every 5 minutes)');
};
