import jwt from 'jsonwebtoken';
import { getConfig } from '../../../shared/index.js';

/**
 * Authenticate JWT token
 */
export const authenticateToken = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        message: 'Access token required'
      });
    }

    const jwtSecret = getConfig('JWT_SECRET', process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production');
    console.log(`🔐 API Gateway Auth: Verifying with secret: ${jwtSecret.substring(0, 10)}...`);
    jwt.verify(token, jwtSecret, (err, decoded) => {
      if (err) {
        console.error(`❌ API Gateway Auth error: ${err.message}`);
        return res.status(403).json({
          message: 'Invalid or expired token'
        });
      }

      // Attach user to request header for downstream services
      req.headers['x-user-id'] = decoded.id;
      req.headers['x-user-email'] = decoded.email;
      req.headers['x-user-role'] = decoded.role;

      req.user = {
        id: decoded.id,
        email: decoded.email,
        role: decoded.role
      };

      next();
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Authentication error'
    });
  }
};

/**
 * Check if user is admin
 */
export const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      message: 'Admin access required'
    });
  }
  next();
};
