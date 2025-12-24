# PROMPT 12: Kafka Event Bus Integration

## Objective
Setup Apache Kafka for event-driven communication between microservices, enabling loose coupling, scalability, and asynchronous processing.

## Requirements

### 1. Kafka Setup & Configuration

#### Docker Compose for Kafka
```yaml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    networks:
      - esante-network

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://kafka:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT_INTERNAL
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    networks:
      - esante-network

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: esante-cluster
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9093
    networks:
      - esante-network

networks:
  esante-network:
    driver: bridge
```

#### Kafka Configuration File
```javascript
// shared/config/kafka.config.js

const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: process.env.KAFKA_CLIENT_ID || 'esante-backend',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
  retry: {
    initialRetryTime: 100,
    retries: 8
  },
  connectionTimeout: 10000,
  requestTimeout: 30000
});

module.exports = kafka;
```

### 2. Kafka Topic Structure

#### Topic Naming Convention
```
{service}.{entity}.{action}

Examples:
- auth.user.registered
- auth.user.verified
- auth.user.logged_in
- appointment.appointment.requested
- appointment.appointment.confirmed
- medical.consultation.created
- medical.prescription.created
- medical.document.uploaded
- referral.referral.created
- message.message.sent
- notification.notification.sent
```

#### Topic List
```javascript
const TOPICS = {
  // Auth Service
  USER_REGISTERED: 'auth.user.registered',
  USER_VERIFIED: 'auth.user.verified',
  USER_LOGGED_IN: 'auth.user.logged_in',
  USER_LOGGED_OUT: 'auth.user.logged_out',
  PASSWORD_RESET: 'auth.user.password_reset',
  
  // User Service
  PROFILE_UPDATED: 'user.profile.updated',
  PHOTO_UPDATED: 'user.photo.updated',
  
  // Appointment Service
  APPOINTMENT_REQUESTED: 'appointment.appointment.requested',
  APPOINTMENT_CONFIRMED: 'appointment.appointment.confirmed',
  APPOINTMENT_REJECTED: 'appointment.appointment.rejected',
  APPOINTMENT_CANCELLED: 'appointment.appointment.cancelled',
  APPOINTMENT_COMPLETED: 'appointment.appointment.completed',
  REFERRAL_BOOKED: 'appointment.appointment.referral_booked',
  
  // Medical Records Service
  CONSULTATION_CREATED: 'medical.consultation.created',
  CONSULTATION_UPDATED: 'medical.consultation.updated',
  CONSULTATION_ACCESSED: 'medical.consultation.accessed',
  PRESCRIPTION_CREATED: 'medical.prescription.created',
  PRESCRIPTION_UPDATED: 'medical.prescription.updated',
  PRESCRIPTION_LOCKED: 'medical.prescription.locked',
  DOCUMENT_UPLOADED: 'medical.document.uploaded',
  DOCUMENT_ACCESSED: 'medical.document.accessed',
  DOCUMENT_DELETED: 'medical.document.deleted',
  
  // Referral Service
  REFERRAL_CREATED: 'referral.referral.created',
  REFERRAL_SCHEDULED: 'referral.referral.scheduled',
  REFERRAL_ACCEPTED: 'referral.referral.accepted',
  REFERRAL_REJECTED: 'referral.referral.rejected',
  REFERRAL_COMPLETED: 'referral.referral.completed',
  REFERRAL_CANCELLED: 'referral.referral.cancelled',
  
  // Messaging Service
  MESSAGE_SENT: 'message.message.sent',
  MESSAGE_DELIVERED: 'message.message.delivered',
  MESSAGE_READ: 'message.message.read',
  
  // Notification Service
  NOTIFICATION_SENT: 'notification.notification.sent',
  
  // Audit Service
  AUDIT_LOG_CREATED: 'audit.log.created'
};

module.exports = TOPICS;
```

### 3. Kafka Producer (Shared Utility)

```javascript
// shared/kafka/producer.js

const kafka = require('../config/kafka.config');

class KafkaProducer {
  constructor() {
    this.producer = kafka.producer({
      allowAutoTopicCreation: true,
      transactionTimeout: 30000
    });
    this.isConnected = false;
  }

  async connect() {
    if (!this.isConnected) {
      await this.producer.connect();
      this.isConnected = true;
      console.log('✅ Kafka Producer connected');
    }
  }

  async disconnect() {
    if (this.isConnected) {
      await this.producer.disconnect();
      this.isConnected = false;
      console.log('❌ Kafka Producer disconnected');
    }
  }

  async sendEvent(topic, event) {
    try {
      await this.connect();

      const message = {
        key: event.id || event.userId || Date.now().toString(),
        value: JSON.stringify({
          ...event,
          timestamp: event.timestamp || Date.now(),
          service: process.env.SERVICE_NAME || 'unknown'
        }),
        headers: {
          'event-type': topic,
          'content-type': 'application/json'
        }
      };

      const result = await this.producer.send({
        topic,
        messages: [message]
      });

      console.log(`📤 Event sent to ${topic}:`, event);
      return result;
    } catch (error) {
      console.error(`❌ Failed to send event to ${topic}:`, error);
      throw error;
    }
  }

  async sendBatch(topic, events) {
    try {
      await this.connect();

      const messages = events.map(event => ({
        key: event.id || event.userId || Date.now().toString(),
        value: JSON.stringify({
          ...event,
          timestamp: event.timestamp || Date.now(),
          service: process.env.SERVICE_NAME || 'unknown'
        }),
        headers: {
          'event-type': topic,
          'content-type': 'application/json'
        }
      }));

      const result = await this.producer.send({
        topic,
        messages
      });

      console.log(`📤 Batch of ${events.length} events sent to ${topic}`);
      return result;
    } catch (error) {
      console.error(`❌ Failed to send batch to ${topic}:`, error);
      throw error;
    }
  }
}

// Singleton instance
const producer = new KafkaProducer();

// Graceful shutdown
process.on('SIGINT', async () => {
  await producer.disconnect();
  process.exit(0);
});

module.exports = producer;
```

#### Usage Example in Service
```javascript
const kafkaProducer = require('../../shared/kafka/producer');
const TOPICS = require('../../shared/kafka/topics');

// In appointment confirmation handler
async function confirmAppointment(appointmentId, doctorId) {
  // ... business logic ...
  
  // Publish event
  await kafkaProducer.sendEvent(TOPICS.APPOINTMENT_CONFIRMED, {
    eventType: 'appointment.confirmed',
    appointmentId,
    patientId: appointment.patientId,
    doctorId,
    appointmentDate: appointment.appointmentDate,
    appointmentTime: appointment.appointmentTime
  });
  
  return appointment;
}
```

### 4. Kafka Consumer (Shared Utility)

```javascript
// shared/kafka/consumer.js

const kafka = require('../config/kafka.config');

class KafkaConsumer {
  constructor(groupId, topics) {
    this.groupId = groupId;
    this.topics = Array.isArray(topics) ? topics : [topics];
    this.consumer = kafka.consumer({
      groupId: this.groupId,
      sessionTimeout: 30000,
      heartbeatInterval: 3000
    });
    this.isConnected = false;
    this.handlers = new Map();
  }

  async connect() {
    if (!this.isConnected) {
      await this.consumer.connect();
      this.isConnected = true;
      console.log(`✅ Kafka Consumer (${this.groupId}) connected`);
    }
  }

  async disconnect() {
    if (this.isConnected) {
      await this.consumer.disconnect();
      this.isConnected = false;
      console.log(`❌ Kafka Consumer (${this.groupId}) disconnected`);
    }
  }

  registerHandler(topic, handler) {
    this.handlers.set(topic, handler);
  }

  async subscribe() {
    await this.connect();
    await this.consumer.subscribe({
      topics: this.topics,
      fromBeginning: false
    });
    console.log(`📥 Subscribed to topics:`, this.topics);
  }

  async startConsuming() {
    await this.subscribe();

    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const event = JSON.parse(message.value.toString());
          
          console.log(`📥 Received event from ${topic}:`, {
            key: message.key?.toString(),
            timestamp: new Date(parseInt(message.timestamp)),
            partition
          });

          const handler = this.handlers.get(topic);
          if (handler) {
            await handler(event);
          } else {
            console.warn(`⚠️ No handler registered for topic: ${topic}`);
          }
        } catch (error) {
          console.error(`❌ Error processing message from ${topic}:`, error);
          // Optionally: Send to dead letter queue
        }
      }
    });
  }
}

module.exports = KafkaConsumer;
```

#### Usage Example in Service
```javascript
// notification-service/consumers/appointment.consumer.js

const KafkaConsumer = require('../../shared/kafka/consumer');
const TOPICS = require('../../shared/kafka/topics');
const { sendAppointmentNotification } = require('../services/notification.service');

const consumer = new KafkaConsumer('notification-service', [
  TOPICS.APPOINTMENT_CONFIRMED,
  TOPICS.APPOINTMENT_REJECTED,
  TOPICS.APPOINTMENT_CANCELLED
]);

// Register handlers
consumer.registerHandler(TOPICS.APPOINTMENT_CONFIRMED, async (event) => {
  console.log('Handling appointment confirmed event:', event);
  await sendAppointmentNotification('confirmed', event);
});

consumer.registerHandler(TOPICS.APPOINTMENT_REJECTED, async (event) => {
  console.log('Handling appointment rejected event:', event);
  await sendAppointmentNotification('rejected', event);
});

consumer.registerHandler(TOPICS.APPOINTMENT_CANCELLED, async (event) => {
  console.log('Handling appointment cancelled event:', event);
  await sendAppointmentNotification('cancelled', event);
});

// Start consuming
consumer.startConsuming().catch(console.error);

module.exports = consumer;
```

### 5. Event Schemas (Documentation)

#### User Registered Event
```javascript
{
  eventType: 'auth.user.registered',
  userId: 'string',
  email: 'string',
  role: 'patient' | 'doctor',
  timestamp: number
}
```

#### Appointment Confirmed Event
```javascript
{
  eventType: 'appointment.appointment.confirmed',
  appointmentId: 'string',
  patientId: 'string',
  doctorId: 'string',
  appointmentDate: 'date',
  appointmentTime: 'string',
  timestamp: number
}
```

#### Consultation Created Event
```javascript
{
  eventType: 'medical.consultation.created',
  consultationId: 'string',
  appointmentId: 'string',
  patientId: 'string',
  doctorId: 'string',
  consultationDate: 'date',
  diagnosis: 'string',
  timestamp: number
}
```

#### Message Sent Event
```javascript
{
  eventType: 'message.message.sent',
  messageId: 'string',
  conversationId: 'string',
  senderId: 'string',
  receiverId: 'string',
  messageType: 'text' | 'image' | 'document',
  timestamp: number
}
```

### 6. Service-Specific Consumer Setup

#### Notification Service Consumers
```javascript
// notification-service/index.js

const appointmentConsumer = require('./consumers/appointment.consumer');
const messageConsumer = require('./consumers/message.consumer');
const referralConsumer = require('./consumers/referral.consumer');
const medicalConsumer = require('./consumers/medical.consumer');

// Start all consumers
async function startConsumers() {
  await appointmentConsumer.startConsuming();
  await messageConsumer.startConsuming();
  await referralConsumer.startConsuming();
  await medicalConsumer.startConsuming();
}

startConsumers().catch(console.error);
```

#### Audit Service Consumer
```javascript
// audit-service/consumers/all-events.consumer.js

const KafkaConsumer = require('../../shared/kafka/consumer');
const { createAuditLog } = require('../services/audit.service');

// Subscribe to ALL topics for audit logging
const consumer = new KafkaConsumer('audit-service', [
  /^auth\..*/,
  /^appointment\..*/,
  /^medical\..*/,
  /^referral\..*/,
  /^message\..*/
]);

// Universal handler
consumer.registerHandler(/.*/, async (event) => {
  await createAuditLog({
    action: event.eventType,
    actionCategory: event.eventType.split('.')[0],
    performedBy: event.userId || event.doctorId,
    performedByType: event.userType || 'system',
    resourceType: event.resourceType,
    resourceId: event.resourceId,
    patientId: event.patientId,
    description: `Event: ${event.eventType}`,
    metadata: event
  });
});

consumer.startConsuming().catch(console.error);
```

### 7. Error Handling & Dead Letter Queue

#### Dead Letter Topic
```javascript
const DLQ_TOPIC = 'esante.dlq';

async function sendToDeadLetterQueue(originalTopic, message, error) {
  await kafkaProducer.sendEvent(DLQ_TOPIC, {
    originalTopic,
    originalMessage: message,
    error: error.message,
    timestamp: Date.now()
  });
}
```

#### Retry Logic
```javascript
async function processMessageWithRetry(handler, event, maxRetries = 3) {
  let attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      await handler(event);
      return;
    } catch (error) {
      attempts++;
      console.error(`Attempt ${attempts} failed:`, error);
      
      if (attempts >= maxRetries) {
        await sendToDeadLetterQueue(event.eventType, event, error);
        throw error;
      }
      
      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempts) * 1000));
    }
  }
}
```

### 8. Monitoring & Health Checks

#### Health Check Endpoint
```javascript
// api-gateway/routes/health.js

router.get('/health/kafka', async (req, res) => {
  try {
    const admin = kafka.admin();
    await admin.connect();
    
    const topics = await admin.listTopics();
    const cluster = await admin.describeCluster();
    
    await admin.disconnect();
    
    res.json({
      status: 'healthy',
      kafka: {
        connected: true,
        brokers: cluster.brokers.length,
        topics: topics.length
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});
```

### 9. Testing Kafka Integration

#### Producer Test
```javascript
// tests/kafka/producer.test.js

const kafkaProducer = require('../shared/kafka/producer');
const TOPICS = require('../shared/kafka/topics');

async function testProducer() {
  await kafkaProducer.sendEvent(TOPICS.USER_REGISTERED, {
    eventType: 'auth.user.registered',
    userId: 'test123',
    email: 'test@example.com',
    role: 'patient'
  });
  
  console.log('✅ Test event sent successfully');
}

testProducer();
```

#### Consumer Test
```javascript
// tests/kafka/consumer.test.js

const KafkaConsumer = require('../shared/kafka/consumer');
const TOPICS = require('../shared/kafka/topics');

const consumer = new KafkaConsumer('test-group', [TOPICS.USER_REGISTERED]);

consumer.registerHandler(TOPICS.USER_REGISTERED, async (event) => {
  console.log('✅ Received test event:', event);
});

consumer.startConsuming();
```

### 10. Event Flow Examples

#### Example 1: Appointment Confirmation Flow
```
1. Patient requests appointment (RDV Service)
   → Publishes: appointment.requested
   
2. Notification Service consumes event
   → Sends notification to doctor
   
3. Audit Service consumes event
   → Logs appointment request
   
4. Doctor confirms appointment (RDV Service)
   → Publishes: appointment.confirmed
   
5. Notification Service consumes event
   → Sends confirmation to patient
   
6. Audit Service consumes event
   → Logs appointment confirmation
```

#### Example 2: Consultation Creation Flow
```
1. Appointment completed (RDV Service)
   → Publishes: appointment.completed
   
2. Medical Records Service consumes event
   → Auto-creates consultation draft
   → Publishes: consultation.created
   
3. Notification Service consumes event
   → Notifies patient consultation available
   
4. Audit Service consumes event
   → Logs consultation creation
```

## Deliverables
1. ✅ Kafka Docker Compose setup
2. ✅ Kafka configuration
3. ✅ Producer utility class
4. ✅ Consumer utility class
5. ✅ Topic definitions
6. ✅ Event schemas
7. ✅ Service-specific consumers
8. ✅ Error handling & DLQ
9. ✅ Health checks
10. ✅ Testing utilities
11. ✅ Documentation

## Testing Checklist
- [ ] Kafka containers start successfully
- [ ] Producer connects and sends events
- [ ] Consumer receives events
- [ ] Multiple consumers work simultaneously
- [ ] Dead letter queue captures failed messages
- [ ] Retry logic works
- [ ] Health check endpoint responsive
- [ ] Events flow between services
- [ ] Audit service logs all events
- [ ] Notification service triggers correctly

---

**Next Step:** After this prompt is complete, proceed to PROMPT 13 (API Gateway & Final Integration)
