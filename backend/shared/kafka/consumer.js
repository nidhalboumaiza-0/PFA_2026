import { createKafkaClient } from '../config/kafka.js';

/**
 * Kafka Consumer Class with Lazy Initialization
 * 
 * The consumer is created lazily (on first connect) to allow
 * bootstrap() to load config from Consul first.
 */
class KafkaConsumer {
  constructor(groupId) {
    this.groupId = groupId;
    this.kafka = null;
    this.consumer = null;
    this.isConnected = false;
    this.handlers = new Map();
  }

  /**
   * Initialize Kafka client and consumer (lazy)
   */
  _initialize() {
    if (!this.kafka) {
      this.kafka = createKafkaClient();
      this.consumer = this.kafka.consumer({
        groupId: this.groupId || process.env.SERVICE_NAME || 'esante-consumer',
        sessionTimeout: 30000,
        heartbeatInterval: 3000
      });
    }
  }

  /**
   * Connect to Kafka
   */
  async connect() {
    if (this.isConnected) {
      return;
    }

    // Lazy initialization - create client now that config is loaded
    this._initialize();

    try {
      await this.consumer.connect();
      this.isConnected = true;
      console.log('✅ Kafka Consumer: Connected successfully');
    } catch (error) {
      console.error('❌ Kafka Consumer: Connection failed:', error.message);
      throw error;
    }
  }

  /**
   * Disconnect from Kafka
   */
  async disconnect() {
    if (!this.isConnected) {
      return;
    }

    try {
      await this.consumer.disconnect();
      this.isConnected = false;
      console.log('👋 Kafka Consumer: Disconnected');
    } catch (error) {
      console.error('❌ Kafka Consumer: Disconnection failed:', error.message);
    }
  }

  /**
   * Subscribe to topics
   */
  async subscribe(topics) {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      const topicArray = Array.isArray(topics) ? topics : [topics];

      for (const topic of topicArray) {
        await this.consumer.subscribe({
          topic,
          fromBeginning: false
        });
        console.log(`📥 Kafka Consumer: Subscribed to topic "${topic}"`);
      }
    } catch (error) {
      console.error('❌ Kafka Consumer: Subscription failed:', error.message);
      throw error;
    }
  }

  /**
   * Register event handler for specific event type
   */
  registerHandler(eventType, handler) {
    this.handlers.set(eventType, handler);
    console.log(`🔧 Kafka Consumer: Handler registered for "${eventType}"`);
  }

  /**
   * Start consuming messages
   */
  async consume() {
    try {
      await this.consumer.run({
        eachMessage: async ({ topic, partition, message }) => {
          try {
            const event = JSON.parse(message.value.toString());
            const eventType = message.headers['event-type']?.toString() || event.eventType;

            console.log(`📩 Kafka Consumer: Received event "${eventType}" from topic "${topic}"`);

            // Find and execute handler
            const handler = this.handlers.get(eventType);
            if (handler) {
              await handler(event);
              console.log(`✅ Kafka Consumer: Event "${eventType}" processed successfully`);
            } else {
              console.warn(`⚠️  Kafka Consumer: No handler for event type "${eventType}"`);
            }
          } catch (error) {
            console.error('❌ Kafka Consumer: Error processing message:', error.message);
            // Optionally send to dead letter queue
            await this.sendToDeadLetterQueue(topic, message, error);
          }
        }
      });
    } catch (error) {
      console.error('❌ Kafka Consumer: Error in consume loop:', error.message);
      throw error;
    }
  }

  /**
   * Send failed message to dead letter queue
   */
  async sendToDeadLetterQueue(originalTopic, message, error) {
    try {
      const dlqTopic = `${originalTopic}.dlq`;
      const { default: producer } = await import('./producer.js');

      await producer.sendEvent(dlqTopic, {
        eventType: 'dlq.message',
        originalTopic,
        originalMessage: message.value.toString(),
        error: error.message,
        timestamp: new Date().toISOString()
      });
    } catch (dlqError) {
      console.error('❌ Failed to send to DLQ:', dlqError.message);
    }
  }
}

export default KafkaConsumer;
