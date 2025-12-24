import morgan from 'morgan';

/**
 * Custom token for user info
 */
morgan.token('user', (req) => {
  return req.user ? `${req.user.id} (${req.user.role})` : 'anonymous';
});

/**
 * Custom logging format
 */
const logFormat = ':method :url :status :response-time ms - :user - :date[iso]';

/**
 * Request logger
 */
const requestLogger = morgan(logFormat, {
  skip: (req, res) => {
    // Skip health check and root endpoints
    return req.url === '/health' || req.url === '/' || req.url === '/favicon.ico';
  }
});

export default requestLogger;
