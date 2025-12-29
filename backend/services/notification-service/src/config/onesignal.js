import * as OneSignal from 'onesignal-node';
import { getConfig } from '../../../../shared/index.js';

let oneSignalClient = null;

export const initializeOneSignal = () => {
  const userAuthKey = getConfig('ONESIGNAL_USER_AUTH_KEY');
  const appAuthKey = getConfig('ONESIGNAL_REST_API_KEY');
  const appId = getConfig('ONESIGNAL_APP_ID');

  if (!userAuthKey || !appAuthKey || !appId) {
    console.warn('⚠️ OneSignal credentials missing. Push notifications will happen in dry-run mode (if handled) or fail.');
  }

  oneSignalClient = new OneSignal.Client({
    userAuthKey: userAuthKey || 'missing_key',
    app: {
      appAuthKey: appAuthKey || 'missing_key',
      appId: appId || 'missing_id',
    },
  });

  console.log('✅ OneSignal client initialized');
  return oneSignalClient;
};

export const getOneSignalClient = () => {
  if (!oneSignalClient) {
    // Attempt lazy init if not explicitly initialized (though bootstrap should handle it)
    return initializeOneSignal();
  }
  return oneSignalClient;
};

export default getOneSignalClient;
