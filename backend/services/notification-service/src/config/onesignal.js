import * as OneSignal from 'onesignal-node';

// Initialize OneSignal client
const oneSignalClient = new OneSignal.Client({
  userAuthKey: process.env.ONESIGNAL_USER_AUTH_KEY,
  app: {
    appAuthKey: process.env.ONESIGNAL_REST_API_KEY,
    appId: process.env.ONESIGNAL_APP_ID,
  },
});

export default oneSignalClient;
