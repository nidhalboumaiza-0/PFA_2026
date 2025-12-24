import morgan from 'morgan';

/**
 * Custom logging format
 */
const customFormat = ':method :url :status :response-time ms - :date[iso]';

/**
 * Request logger middleware
 */
export const requestLogger = morgan(customFormat, {
  skip: (req, res) => {
    // Skip health check endpoints
    return req.url === '/health' || req.url === '/';
  },
  stream: {
    write: (message) => {
      console.log(message.trim());
    }
  }
});

/**
 * Request info extractor
 */
export const getRequestInfo = (req) => {
  return {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.get('user-agent'),
    timestamp: new Date().toISOString()
  };
};
