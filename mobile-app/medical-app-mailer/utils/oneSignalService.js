const OneSignal = require("onesignal-node");

// Initialize the OneSignal client
const client = new OneSignal.Client(
  process.env.ONESIGNAL_APP_ID,
  process.env.ONESIGNAL_API_KEY
);

/**
 * Send notification to specific users
 * @param {Array} playerIds - Array of OneSignal player IDs
 * @param {String} title - Notification title
 * @param {String} message - Notification message
 * @param {Object} additionalData - Additional data to send with notification
 * @returns {Promise} - OneSignal response
 */
const sendNotificationToUsers = async (
  playerIds,
  title,
  message,
  additionalData = {}
) => {
  try {
    const notification = {
      contents: {
        en: message,
      },
      headings: {
        en: title,
      },
      include_player_ids: playerIds,
      data: additionalData,
    };

    const response = await client.createNotification(notification);
    console.log("OneSignal notification sent:", response.body.id);
    return response;
  } catch (error) {
    console.error("Error sending OneSignal notification:", error);
    throw error;
  }
};

/**
 * Send notification to all subscribed users
 * @param {String} title - Notification title
 * @param {String} message - Notification message
 * @param {Object} additionalData - Additional data to send with notification
 * @returns {Promise} - OneSignal response
 */
const sendNotificationToAll = async (
  title,
  message,
  additionalData = {}
) => {
  try {
    const notification = {
      contents: {
        en: message,
      },
      headings: {
        en: title,
      },
      included_segments: ["Subscribed Users"],
      data: additionalData,
    };

    const response = await client.createNotification(notification);
    console.log(
      "OneSignal notification sent to all users:",
      response.body.id
    );
    return response;
  } catch (error) {
    console.error(
      "Error sending OneSignal notification to all users:",
      error
    );
    throw error;
  }
};

/**
 * Send notification to users by filters (segments)
 * @param {Array} filters - Array of filter objects
 * @param {String} title - Notification title
 * @param {String} message - Notification message
 * @param {Object} additionalData - Additional data to send with notification
 * @returns {Promise} - OneSignal response
 */
const sendNotificationByFilters = async (
  filters,
  title,
  message,
  additionalData = {}
) => {
  try {
    const notification = {
      contents: {
        en: message,
      },
      headings: {
        en: title,
      },
      filters,
      data: additionalData,
    };

    const response = await client.createNotification(notification);
    console.log(
      "OneSignal notification sent by filters:",
      response.body.id
    );
    return response;
  } catch (error) {
    console.error(
      "Error sending OneSignal notification by filters:",
      error
    );
    throw error;
  }
};

module.exports = {
  sendNotificationToUsers,
  sendNotificationToAll,
  sendNotificationByFilters,
};
