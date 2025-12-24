import mongoose from 'mongoose';

/**
 * MongoDB Connection Helper
 * Handles connection, reconnection, and error logging
 */
class DatabaseConnection {
  constructor() {
    this.isConnected = false;
    this.maxRetries = 5;
    this.retryDelay = 5000; // 5 seconds
    this.currentRetry = 0;
  }

  /**
   * Connect to MongoDB with retry logic
   * @param {string} uri - MongoDB connection URI
   * @param {object} options - Mongoose connection options
   */
  async connect(uri, options = {}) {
    if (this.isConnected) {
      console.log('✅ MongoDB: Already connected');
      return;
    }

    const defaultOptions = {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      ...options
    };

    try {
      await mongoose.connect(uri, defaultOptions);
      this.isConnected = true;
      this.currentRetry = 0;
      
      console.log(`✅ MongoDB: Connected successfully to ${this.getDatabaseName(uri)}`);
      
      this.setupEventHandlers();
    } catch (error) {
      console.error('❌ MongoDB: Connection failed:', error.message);
      await this.handleConnectionError(uri, options);
    }
  }

  /**
   * Setup MongoDB event handlers
   */
  setupEventHandlers() {
    mongoose.connection.on('connected', () => {
      console.log('📡 MongoDB: Connection established');
    });

    mongoose.connection.on('error', (err) => {
      console.error('❌ MongoDB: Error occurred:', err.message);
      this.isConnected = false;
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  MongoDB: Disconnected');
      this.isConnected = false;
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
      await this.disconnect();
      process.exit(0);
    });
  }

  /**
   * Handle connection errors with retry logic
   */
  async handleConnectionError(uri, options) {
    if (this.currentRetry < this.maxRetries) {
      this.currentRetry++;
      console.log(`🔄 MongoDB: Retry attempt ${this.currentRetry}/${this.maxRetries} in ${this.retryDelay / 1000}s...`);
      
      await this.sleep(this.retryDelay);
      await this.connect(uri, options);
    } else {
      console.error(`❌ MongoDB: Max retries (${this.maxRetries}) reached. Exiting...`);
      process.exit(1);
    }
  }

  /**
   * Disconnect from MongoDB
   */
  async disconnect() {
    if (!this.isConnected) {
      return;
    }

    try {
      await mongoose.connection.close();
      this.isConnected = false;
      console.log('👋 MongoDB: Disconnected gracefully');
    } catch (error) {
      console.error('❌ MongoDB: Error during disconnection:', error.message);
    }
  }

  /**
   * Get database name from URI
   */
  getDatabaseName(uri) {
    try {
      const matches = uri.match(/\/([^/?]+)(\?|$)/);
      return matches ? matches[1] : 'unknown';
    } catch {
      return 'unknown';
    }
  }

  /**
   * Sleep utility for retry delays
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Get connection status
   */
  getStatus() {
    return {
      isConnected: this.isConnected,
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      name: mongoose.connection.name
    };
  }
}

// Export singleton instance
const dbConnection = new DatabaseConnection();

export const connectDB = (uri, options) => dbConnection.connect(uri, options);
export const disconnectDB = () => dbConnection.disconnect();
export const getDBStatus = () => dbConnection.getStatus();
export { mongoose };
