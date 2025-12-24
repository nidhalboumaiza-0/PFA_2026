import jwt from 'jsonwebtoken';

/**
 * Verify JWT token and attach user to request
 */
export const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({ message: 'Access token required' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    req.token = token;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

/**
 * Alternative name for auth (for compatibility)
 */
export const authenticateToken = auth;

/**
 * Admin authentication middleware
 */
export const adminAuth = async (req, res, next) => {
  try {
    await auth(req, res, () => {
      if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied. Admin only.' });
      }
      next();
    });
  } catch (error) {
    res.status(401).json({ message: 'Please authenticate' });
  }
};

/**
 * Flexible authorization middleware that accepts multiple roles
 */
export const authorize = (roles) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({ message: 'Please authenticate' });
      }

      if (!roles.includes(req.user.role)) {
        return res.status(403).json({
          message: `Access denied. Required roles: ${roles.join(', ')}`
        });
      }

      next();
    } catch (error) {
      res.status(401).json({ message: 'Please authenticate' });
    }
  };
};

/**
 * Optional authentication - doesn't fail if no token
 */
export const optionalAuth = (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      req.user = null;
      return next();
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
        req.user = null;
      } else {
        req.user = decoded;
      }
      next();
    });
  } catch (error) {
    req.user = null;
    next();
  }
};
