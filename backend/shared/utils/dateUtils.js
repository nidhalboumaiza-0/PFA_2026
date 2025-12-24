/**
 * Format date to readable string
 */
export const formatDate = (date, includeTime = false) => {
  const d = new Date(date);
  
  const options = {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    ...(includeTime && {
      hour: '2-digit',
      minute: '2-digit'
    })
  };

  return d.toLocaleDateString('fr-FR', options);
};

/**
 * Add days to date
 */
export const addDays = (date, days) => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

/**
 * Add hours to date
 */
export const addHours = (date, hours) => {
  const result = new Date(date);
  result.setHours(result.getHours() + hours);
  return result;
};

/**
 * Get difference in days
 */
export const getDaysDifference = (date1, date2) => {
  const diffTime = Math.abs(new Date(date2) - new Date(date1));
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

/**
 * Check if date is today
 */
export const isToday = (date) => {
  const today = new Date();
  const compareDate = new Date(date);
  
  return today.getDate() === compareDate.getDate() &&
         today.getMonth() === compareDate.getMonth() &&
         today.getFullYear() === compareDate.getFullYear();
};

/**
 * Get start of day
 */
export const getStartOfDay = (date = new Date()) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Get end of day
 */
export const getEndOfDay = (date = new Date()) => {
  const d = new Date(date);
  d.setHours(23, 59, 59, 999);
  return d;
};

/**
 * Check if time slot overlaps
 */
export const doTimeSlotsOverlap = (start1, end1, start2, end2) => {
  return start1 < end2 && start2 < end1;
};
