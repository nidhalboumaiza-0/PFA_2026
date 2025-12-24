import { Kafka, logLevel } from 'kafkajs';

/**
 * Kafka Client Configuration
 */
export const createKafkaClient = () => {
  const kafka = new Kafka({
    clientId: process.env.KAFKA_CLIENT_ID || 'esante-backend',
    brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
    logLevel: logLevel.INFO,
    retry: {
      initialRetryTime: 300,
      retries: 8
    }
  });

  return kafka;
};
