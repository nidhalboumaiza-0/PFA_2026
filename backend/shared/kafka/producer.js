import { createKafkaClient } from '../config/kafka.js';

/**
 * Kafka Producer Singleton with Lazy Initialization
 * 
 * The producer is created lazily (on first connect) to allow
 * bootstrap() to load config from Consul first.
 */
class KafkaProducer {
  constructor() {
    this.kafka = null;
    this.producer = null;
    this.isConnected = false;
  }

  /**
   * Initialize Kafka client and producer (lazy)
   */
  _initialize() {
    if (!this.kafka) {
      this.kafka = createKafkaClient();
      this.producer = this.kafka.producer({
        allowAutoTopicCreation: true,
        transactionTimeout: 30000
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
      await this.producer.connect();
      this.isConnected = true;
      console.log('✅ Kafka Producer: Connected successfully');
    } catch (error) {
      console.error('❌ Kafka Producer: Connection failed:', error.message);
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
      await this.producer.disconnect();
      this.isConnected = false;
      console.log('👋 Kafka Producer: Disconnected');
    } catch (error) {
      console.error('❌ Kafka Producer: Disconnection failed:', error.message);
    }
  }

  /**
   * Send event to Kafka topic
   */
  async sendEvent(topic, event) {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      const message = {
        key: event.eventId || Date.now().toString(),
        value: JSON.stringify({
          ...event,
          timestamp: new Date().toISOString(),
          service: process.env.SERVICE_NAME || 'unknown'
        }),
        headers: {
          'content-type': 'application/json',
          'event-type': event.eventType
        }
      };

      await this.producer.send({
        topic,
        messages: [message]
      });

      console.log(`📤 Kafka: Event sent to topic "${topic}":`, event.eventType);
    } catch (error) {
      console.error(`❌ Kafka: Failed to send event to "${topic}":`, error.message);
      throw error;
    }
  }

  /**
   * Send multiple events in batch
   */
  async sendBatch(topic, events) {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      const messages = events.map(event => ({
        key: event.eventId || Date.now().toString(),
        value: JSON.stringify({
          ...event,
          timestamp: new Date().toISOString(),
          service: process.env.SERVICE_NAME || 'unknown'
        }),
        headers: {
          'content-type': 'application/json',
          'event-type': event.eventType
        }
      }));

      await this.producer.send({
        topic,
        messages
      });

      console.log(`📤 Kafka: Batch of ${events.length} events sent to topic "${topic}"`);
    } catch (error) {
      console.error(`❌ Kafka: Failed to send batch to "${topic}":`, error.message);
      throw error;
    }
  }
}

// Export singleton instance
const kafkaProducer = new KafkaProducer();

// Named export for publishToKafka (helper function)
export const publishToKafka = async (topic, event) => {
  return kafkaProducer.sendEvent(topic, event);
};

// Export the producer instance methods
export const connectProducer = () => kafkaProducer.connect();
export const disconnectProducer = () => kafkaProducer.disconnect();
export const sendBatchToKafka = (topic, events) => kafkaProducer.sendBatch(topic, events);

export default kafkaProducer;
