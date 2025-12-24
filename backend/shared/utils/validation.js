/**
 * Email validation
 */
export const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Phone number validation (Moroccan format)
 */
export const isValidPhone = (phone) => {
  const phoneRegex = /^(\+212|0)[567]\d{8}$/;
  return phoneRegex.test(phone);
};

/**
 * Password strength validation
 */
export const isStrongPassword = (password) => {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
  return passwordRegex.test(password);
};

/**
 * Date validation
 */
export const isValidDate = (dateString) => {
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date);
};

/**
 * Check if date is in the past
 */
export const isPastDate = (dateString) => {
  const date = new Date(dateString);
  return date < new Date();
};

/**
 * Check if date is in the future
 */
export const isFutureDate = (dateString) => {
  const date = new Date(dateString);
  return date > new Date();
};

/**
 * MongoDB ObjectId validation
 */
export const isValidObjectId = (id) => {
  return /^[0-9a-fA-F]{24}$/.test(id);
};

/**
 * Sanitize input (remove HTML tags)
 */
export const sanitizeInput = (input) => {
  if (typeof input !== 'string') return input;
  return input.replace(/<[^>]*>/g, '');
};

/**
 * Validate required fields
 */
export const validateRequiredFields = (data, requiredFields) => {
  const missingFields = [];

  requiredFields.forEach(field => {
    if (!data[field] || data[field] === '') {
      missingFields.push(field);
    }
  });

  return {
    isValid: missingFields.length === 0,
    missingFields
  };
};
