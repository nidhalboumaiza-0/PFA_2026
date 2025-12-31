/**
 * Standardized success response formatter
 * @param {Response} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {string} message - User-friendly success message
 * @param {object} data - Response data (optional)
 */
export const sendSuccess = (res, statusCode, message, data = null) => {
  const response = {
    success: true,
    message,
    ...(data && { data })
  };
  return res.status(statusCode).json(response);
};

/**
 * Standardized error response formatter
 * @param {Response} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {string} code - Error code for frontend handling (e.g., 'SLOT_NOT_AVAILABLE')
 * @param {string} message - User-friendly error message
 * @param {object} details - Additional error details (optional)
 */
export const sendError = (res, statusCode, code, message, details = null) => {
  const response = {
    success: false,
    error: {
      code,
      message,
      ...(details && { details })
    }
  };
  return res.status(statusCode).json(response);
};

// Legacy aliases for backward compatibility
export const successResponse = sendSuccess;
export const errorResponse = (res, statusCode, message, errors = null) => {
  return sendError(res, statusCode, 'ERROR', message, errors ? { errors } : null);
};

/**
 * Paginated response formatter
 */
export const paginatedResponse = (res, data, page, limit, total) => {
  return res.status(200).json({
    success: true,
    data,
    pagination: {
      currentPage: parseInt(page),
      totalPages: Math.ceil(total / limit),
      totalItems: total,
      itemsPerPage: parseInt(limit),
      hasNextPage: page * limit < total,
      hasPrevPage: page > 1
    }
  });
};
